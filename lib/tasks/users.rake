namespace :users do
  desc 'Update all users with their full_name and ensure last names are fully capitalized'
  task update_full_names: :environment do
    puts 'Updating full_name and fully capitalizing last names for all users...'
    count = 0

    User.find_each do |user|
      # Fully capitalize last name if present
      user.last_name = user.last_name.strip.upcase if user.last_name.present?

      # Set full name
      user.send(:set_full_name)

      count += 1 if user.save(validate: false)
    end

    puts "Updated #{count} users with fully capitalized last names and full_name."
  end
end
