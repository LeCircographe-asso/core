# syntax=docker/dockerfile:1
# check=error=true

# This Dockerfile is designed for production, not development. Use with Kamal or build'n'run by hand:
# docker build -t circographe .
# docker run -d -p 80:80 -e RAILS_MASTER_KEY=<value from config/master.key> --name circographe circographe

# For a containerized dev environment, see Dev Containers: https://guides.rubyonrails.org/getting_started_with_devcontainer.html

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version
ARG RUBY_VERSION=3.2.5
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

# Rails app lives here
WORKDIR /rails

# Install base packages optimisées pour VPS Ionos Linux M
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    curl \
    libjemalloc2 \
    libvips \
    sqlite3 \
    && rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Set bundle configuration (RAILS_ENV will be set at runtime via Kamal)
ENV BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development"

# Throw-away build stage to reduce size of final image
FROM base AS build

# Layer 1: Install Bundler (changes rarely)
RUN gem install bundler:2.5.23

# Layer 2: Install system dependencies (changes rarely)
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    build-essential \
    git \
    pkg-config \
    && rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Layer 3: Install gems (changes when Gemfile changes)
COPY Gemfile Gemfile.lock ./
RUN bundle install --jobs 4 && \
    rm -rf ~/.bundle/ \
    "${BUNDLE_PATH}"/ruby/*/cache \
    "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git \
    "${BUNDLE_PATH}"/ruby/*/gems/*/test \
    "${BUNDLE_PATH}"/ruby/*/gems/*/spec \
    && bundle exec bootsnap precompile --gemfile

# Layer 4: Copy application code (changes frequently)
COPY . .

# Layer 5: Precompile bootsnap (depends on code)
RUN bundle exec bootsnap precompile app/ lib/

# Layer 6: Precompile assets (depends on code and assets)
# Use development mode to avoid environment-specific configs and secret requirements
RUN SECRET_KEY_BASE_DUMMY=1 \
    RAILS_ENV=development \
    ./bin/rails assets:precompile

# Final stage for app image
FROM base

# Set production environment variables
ENV LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.2

# Copy built artifacts: gems, application
COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

# Run and own only the runtime files as a non-root user for security
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    mkdir -p /app/log /app/tmp/pids && \
    chown -R rails:rails db log storage tmp /app/log /app/tmp
USER 1000:1000

# Entrypoint prepares the database.
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Start server via Thruster by default, this can be overwritten at runtime
EXPOSE 80
CMD ["./bin/thrust", "./bin/rails", "server"]
