require 'fileutils'

namespace :importmap do
  desc 'Ensure third-party ES modules pinned via Importmap have non-digested copies after assets:precompile'
  task normalize_modules: :environment do
    modules_dir = Rails.public_path.join('assets/_')
    unless Dir.exist?(modules_dir)
      puts "[importmap] no modules directory at #{modules_dir}, skipping"
      next
    end

    Dir.glob(modules_dir.join('*-*.js')).each do |path|
      digest_name = File.basename(path)
      short_name = digest_name.sub(/-[^-]+\.js\z/, '.js')

      next if short_name == digest_name

      short_path = modules_dir.join(short_name)
      FileUtils.cp(path, short_path)
      puts "[importmap] ensured #{short_name}"
    end
  end
end

Rake::Task['assets:precompile'].enhance do
  Rake::Task['importmap:normalize_modules'].invoke
end
