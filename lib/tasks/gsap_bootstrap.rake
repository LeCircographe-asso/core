# frozen_string_literal: true

namespace :gsap do
  desc "Rebuild vendor/javascript/gsap-bootstrap.js from vendor/javascript/gsap (slim tree) + register.esbuild-entry.js (requires npx esbuild). After upgrading GSAP, re-extract npm package then trim or restore full tree before rebundle."
  task bootstrap: :environment do
    entry = Rails.root.join("app/javascript/lib/gsap/register.esbuild-entry.js")
    outfile = Rails.root.join("vendor/javascript/gsap-bootstrap.js")
    raise "Missing #{entry}" unless entry.exist?

    cmd = [
      "npx", "--yes", "esbuild",
      entry.to_s,
      "--bundle",
      "--format=esm",
      "--outfile=#{outfile}",
      "--legal-comments=none"
    ]
    puts cmd.join(" ")
    system(*cmd, exception: true)
    puts "Wrote #{outfile} (#{File.size(outfile)} bytes)"
  end
end
