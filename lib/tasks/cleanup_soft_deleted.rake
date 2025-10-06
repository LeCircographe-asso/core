namespace :users do
  desc "Clean up soft deleted users - restore them to active status"
  task cleanup_soft_deleted: :environment do
    puts "🧹 Cleaning up soft deleted users..."

    # Find all users with deleted_at timestamp
    soft_deleted_users = User.unscoped.where.not(deleted_at: nil)

    if soft_deleted_users.any?
      puts "  Found #{soft_deleted_users.count} soft deleted users"

      restored_count = 0
      soft_deleted_users.each do |user|
        begin
          # Restore the user by clearing deleted_at
          user.update_columns(
            deleted_at: nil,
            deleted: false
          )

          # Restore original email if it was anonymized
          if user.email_address.start_with?("deleted_")
            # Generate a new email since we can't know the original
            user.update_columns(
              email_address: "restored_#{user.id}@example.com"
            )
          end

          # Restore original name if it was anonymized
          if user.first_name == "Deleted" && user.last_name == "User"
            user.update_columns(
              first_name: "Restored",
              last_name: "User#{user.id}",
              full_name: "Restored User#{user.id}"
            )
          end

          restored_count += 1
          print "."
        rescue => e
          puts "\n  Error restoring user #{user.id}: #{e.message}"
        end
      end
      puts "\n  ✅ Restored #{restored_count} users"
    else
      puts "  ✅ No soft deleted users found"
    end

    # Also clean up any related soft deleted records
    puts "\n🧹 Cleaning up related soft deleted records..."

    # Clean up payments
    soft_deleted_payments = Payment.unscoped.where.not(deleted_at: nil)
    if soft_deleted_payments.any?
      soft_deleted_payments.update_all(deleted_at: nil)
      puts "  ✅ Restored #{soft_deleted_payments.count} payments"
    end

    # Clean up user_memberships
    soft_deleted_memberships = UserMembership.unscoped.where.not(deleted_at: nil)
    if soft_deleted_memberships.any?
      soft_deleted_memberships.update_all(deleted_at: nil)
      puts "  ✅ Restored #{soft_deleted_memberships.count} user memberships"
    end

    # Clean up orders
    soft_deleted_orders = Order.unscoped.where.not(deleted_at: nil)
    if soft_deleted_orders.any?
      soft_deleted_orders.update_all(deleted_at: nil)
      puts "  ✅ Restored #{soft_deleted_orders.count} orders"
    end

    # Clean up book_of_entries
    soft_deleted_books = BookOfEntry.unscoped.where.not(deleted_at: nil)
    if soft_deleted_books.any?
      soft_deleted_books.update_all(deleted_at: nil)
      puts "  ✅ Restored #{soft_deleted_books.count} book of entries"
    end

    # Clean up attendances
    soft_deleted_attendances = Attendance.unscoped.where.not(deleted_at: nil)
    if soft_deleted_attendances.any?
      soft_deleted_attendances.update_all(deleted_at: nil)
      puts "  ✅ Restored #{soft_deleted_attendances.count} attendances"
    end

    puts "\n🎉 Cleanup complete! All soft deleted records have been restored."
  end
end
