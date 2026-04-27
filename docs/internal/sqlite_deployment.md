# Bare-metal SQLite deployment — Rails 8.1 + SQLite3 (VPS Linux)

> **Statut** : internal (procédure alternative non testée en CI)
> **Public cible** : équipe ops
> **Provenance** : ex-`docs/operations/sqlite_deployment.md`, déplacé dans `docs/internal/` car non maintenu en CI ; conservé comme plan B.
>
> **Alternative au flux Kamal** documenté dans [`../operations/deployment.md`](../operations/deployment.md).
> Conserver ce guide pour les cas où l'on veut déployer sans conteneurs (single VPS + systemd).

This document describes a pragmatic, fast setup for deploying this Rails 8.1 app on a small VPS (e.g., IONOS Linux M) using SQLite3 in production. It focuses on performance, reliability, and simplicity.

### 1) System prerequisites
- Linux (Ubuntu/Debian recommended)
- Packages:
  ```bash
  sudo apt update
  sudo apt install -y build-essential git curl libssl-dev zlib1g-dev libreadline-dev libyaml-dev libffi-dev
  ```

### 2) Ruby and Bundler (rbenv)
```bash
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
cd ~/.rbenv && src/configure && make -C src
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init - bash)"' >> ~/.bashrc
exec $SHELL -l
git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build

cd /var/www/app # or the chosen path
git clone <YOUR_REPO_URL> core
cd core
rbenv install 4.0.1
rbenv local 4.0.1
ruby -v
gem install bundler
bundle install --without development test
```

### 3) Node-less assets and Tailwind
- Assets are precompiled; Tailwind must be built during deploy/CI (not at runtime).
```bash
RAILS_ENV=production bin/rails assets:precompile
```

### 4) SQLite3 production settings
SQLite is fast for small-to-medium traffic when tuned properly. Enable WAL and recommended PRAGMAs once after provisioning or at boot.

Apply PRAGMAs (one-off or at boot):
```bash
RAILS_ENV=production bin/rails runner '
  ActiveRecord::Base.connection.execute(<<~SQL)
    PRAGMA journal_mode=WAL;
    PRAGMA synchronous=NORMAL;
    PRAGMA busy_timeout=5000;
    PRAGMA cache_size=-20000;      -- ~20 MB
    PRAGMA mmap_size=134217728;    -- 128 MB
  SQL
'
```

Important:
- Backup all three files: `db/production.sqlite3`, `db/production.sqlite3-wal`, `db/production.sqlite3-shm`.
- Set pool to match Puma threads (see below).

### 5) Environment variables (production)
Set via systemd/Kamal/platform secrets:
- `RAILS_ENV=production`
- `RAILS_LOG_TO_STDOUT=1`
- `RAILS_SERVE_STATIC_FILES=1` (if serving static files directly)
- `WEB_CONCURRENCY=2` (workers)
- `RAILS_MAX_THREADS=5` (threads)
- `RUBYOPT=--yjit` (enable YJIT)

### 6) Puma configuration (baseline)
File: `config/puma.rb` (ensure these points exist):
- `workers ENV.fetch("WEB_CONCURRENCY", 2)`
- `threads_count = ENV.fetch("RAILS_MAX_THREADS", 5)` and `threads threads_count, threads_count`
- `preload_app!`

Start command (example):
```bash
RUBYOPT="--yjit" WEB_CONCURRENCY=2 RAILS_MAX_THREADS=5 \
RAILS_ENV=production bin/rails server
```

### 7) Reverse proxy (recommended)
- Put Caddy or Nginx in front of Puma:
  - TLS termination (HTTPS)
  - HTTP/2
  - Gzip/Brotli compression
  - Cache for static assets

If you don’t want a proxy, consider Thruster for HTTP-level compression/caching. Keep it simple.

### 8) Caching, sessions, jobs
- Caching: use Solid Cache (Rails 8 default)
  - In `config/environments/production.rb`: `config.cache_store = :solid_cache_store`
- Sessions: prefer cookie store to avoid DB writes.
- Background jobs: Solid Queue if needed (otherwise keep synchronous).

### 9) Hotwire and rendering
- Use Turbo Streams for partial updates to reduce server-side rendering cost.
- Pagination and eager loading on list pages.
- Avoid N+1 queries; add indexes as needed.

### 10) Logging and healthchecks
- `config.log_level = :info` in production.
- Silence healthcheck endpoints in logs.
- Use logrotate/journald for rotation.

### 11) Deploy options
Option A — Kamal 2 (recommended for zero-downtime):
- Containerize app, configure `kamal.yml`, set healthchecks, run `kamal deploy`.

Option B — Single server (systemd):
Create a `systemd` unit for Puma, set env vars, start on boot.

Example service (`/etc/systemd/system/circographe.service`):
```ini
[Unit]
Description=Circographe Rails App
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=/var/www/app/core
Environment=RAILS_ENV=production
Environment=RAILS_LOG_TO_STDOUT=1
Environment=RAILS_SERVE_STATIC_FILES=1
Environment=WEB_CONCURRENCY=2
Environment=RAILS_MAX_THREADS=5
Environment=RUBYOPT=--yjit
ExecStart=/bin/bash -lc 'bin/rails server -b 0.0.0.0 -p 3000'
Restart=always
TimeoutStopSec=15

[Install]
WantedBy=multi-user.target
```

Then:
```bash
sudo systemctl daemon-reload
sudo systemctl enable circographe
sudo systemctl start circographe
```

### 12) Verification checklist
- Boots in production: `curl -I http://127.0.0.1:3000/health` (or your root path)
- No errors in logs; Tailwind assets served and fingerprinted
- DB WAL files present; PRAGMAs applied (no lock storms)
- Caching working; pages fast; no N+1s
- Reverse proxy serves HTTPS, compression enabled

### 13) When to outgrow SQLite
- Heavy concurrent writes, reporting/analytics, replication/HA needs → migrate to PostgreSQL.

### 14) Useful one-liners
```bash
# Precompile on server during deploy
RAILS_ENV=production bin/rails assets:precompile

# Apply SQLite PRAGMAs again if needed
RAILS_ENV=production bin/rails runner 'ActiveRecord::Base.connection.execute("PRAGMA journal_mode=WAL; PRAGMA synchronous=NORMAL; PRAGMA busy_timeout=5000; PRAGMA cache_size=-20000; PRAGMA mmap_size=134217728;")'

# Tail logs
tail -f log/production.log
```


