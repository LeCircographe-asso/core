namespace :data_fixes do
  desc "Fix orphaned payments by assigning them to an admin user"
  task fix_orphaned_payments: :environment do
    puts "=== Fixing Orphaned Payments ==="

    # Find admin user to assign orphaned payments to
    admin_user = User.where(system_role: "admin").first

    if admin_user.nil?
      puts "Error: No admin user found. Please create an admin user first."
      exit 1
    end

    # Find orphaned payments
    orphaned_payments = Payment.left_joins(:user).where(users: { id: nil })
    orphaned_count = orphaned_payments.count
    orphaned_total = orphaned_payments.sum(:payment_amount)

    puts "Found #{orphaned_count} orphaned payments for a total of #{orphaned_total}"

    # Update orphaned payments to be associated with admin user
    orphaned_payments.update_all(user_id: admin_user.id)

    puts "All orphaned payments have been assigned to admin user: #{admin_user.full_name} (ID: #{admin_user.id})"

    # Verify fix worked
    remaining_orphaned = Payment.left_joins(:user).where(users: { id: nil }).count
    puts "Remaining orphaned payments: #{remaining_orphaned}"

    # Check reconciliation
    total_all = Payment.sum(:payment_amount)
    total_by_user = User.joins(:payments).group(:id).sum("payments.payment_amount").values.sum
    difference = total_all - total_by_user

    puts "Total all payments: #{total_all}"
    puts "Total by users: #{total_by_user}"
    puts "Difference: #{difference}"

    if difference.zero?
      puts "✓ Payment reconciliation is now correct!"
    else
      puts "✗ Payment reconciliation still has issues. Difference: #{difference}"
    end
  end

  desc "Run all data fixes"
  task all: [ :fix_orphaned_payments ] do
    puts "All data fixes have been applied."
  end
end
