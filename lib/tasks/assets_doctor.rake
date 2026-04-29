namespace :assets do
  desc 'Quick checks for Tailwind/Flowbite/fonts setup'
  task :doctor do
    errors = []

    tailwind_entry = Rails.root.join('app/assets/tailwind/application.css')
    errors << "Missing #{tailwind_entry}" unless File.exist?(tailwind_entry)

    flowbite_js = Rails.root.join('vendor/js/flowbite.turbo.min.js')
    flowbite_css = Rails.root.join('vendor/js/flowbite.css')
    errors << 'Missing vendor/js/flowbite.turbo.min.js' unless File.exist?(flowbite_js)
    errors << 'Missing vendor/js/flowbite.css' unless File.exist?(flowbite_css)

    fonts_dir = Rails.root.join('app/assets/fonts')
    errors << 'No fonts found in app/assets/fonts (expected .woff2/.woff/.otf)' if !Dir.exist?(fonts_dir) || Dir.children(fonts_dir).grep(/\.(woff2|woff|otf)$/i).empty?

    layout = Rails.root.join('app/views/layouts/application.html.erb')
    layout_text = File.read(layout)
    errors << 'Layout: tailwind stylesheet_link_tag missing' unless layout_text.include?('stylesheet_link_tag "tailwind"')
    errors << 'Layout: flowbite stylesheet_link_tag missing' unless layout_text.include?('stylesheet_link_tag "flowbite"')
    errors << 'Layout: flowbite.turbo.min javascript_include_tag missing' unless layout_text.include?('javascript_include_tag "flowbite.turbo.min"')

    if errors.any?
      puts "\nAssets Doctor – FAIL".freeze
      errors.each { |e| puts " - #{e}" }
      abort
    else
      puts "\nAssets Doctor – OK".freeze
    end
  end
end
