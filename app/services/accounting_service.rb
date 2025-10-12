class AccountingService
  def self.total_sales(period: nil, include_deleted: true)
    scope = include_deleted ? Payment.all : Payment.joins(:user).where(users: { deleted_at: nil })
    scope = scope.where(payment_date: period) if period
    scope.sum(:payment_amount)
  end

  def self.product_sales_report(membership_type: nil)
    query = Payment.joins(order: :product_orders)
             .joins("INNER JOIN products ON product_orders.product_id = products.id")

    if membership_type.present?
      query = query.where(products: { product_type: membership_type })
    end

    query.group("products.name")
         .select("products.name, SUM(payments.payment_amount) as total, COUNT(*) as count")
  end

  def self.monthly_report(year: Date.current.year, month: Date.current.month)
    start_date = Date.new(year, month, 1).beginning_of_day
    end_date = start_date.end_of_month.end_of_day

    {
      total_sales: total_sales(period: start_date..end_date),
      new_members: UserMembership.where(created_at: start_date..end_date).count,
      payments_by_type: Payment.where(payment_date: start_date..end_date)
                              .group(:payment_method)
                              .count
    }
  end
end
