# frozen_string_literal: true

module Admin
  class PaymentsService
    def initialize(params = {})
      @params = params
    end

    def call
      @filtered_payments = filtered_payments # Cache to avoid multiple evaluations
      {
        payments: @filtered_payments,
        total_amount: calculate_total_amount,
        total_donation: calculate_total_donation,
        pagy: pagy_result
      }
    end

    private

    attr_reader :params

    def base_query
      PaymentQuery.with_person_and_recorded_by
    end

    def filtered_payments
      query = base_query

      # Filter by person if person_id is provided
      if params[:person_id].present?
        person = Person.find_by(id: params[:person_id])
        query = query.where(person_id: person.id) if person
      end

      # Apply status filter
      query = query.where(status: params[:status]) if params[:status].present?

      # Apply date range filter
      if params[:start_date].present? && params[:end_date].present?
        start_date = Date.parse(params[:start_date])
        end_date = Date.parse(params[:end_date])
        query = query.where(created_at: start_date.beginning_of_day..end_date.end_of_day)
      end

      # Apply search filter
      if params[:search].present?
        search_term = "%#{params[:search]}%"
        query = query.joins(:person)
                     .where(
                       'people.first_name LIKE ? COLLATE NOCASE OR people.last_name LIKE ? COLLATE NOCASE OR people.email LIKE ? COLLATE NOCASE OR CAST(payments.total_cents AS TEXT) LIKE ? COLLATE NOCASE',
                       search_term, search_term, search_term, search_term
                     )
      end

      query
    end

    def calculate_total_amount
      @filtered_payments.where(status: :success).sum(:total_cents)
    end

    def calculate_total_donation
      @filtered_payments
        .where(status: :success)
        .joins(:payment_lines)
        .where(payment_lines: { item_type: 'Donation' })
        .sum('payment_lines.amount_cents')
    end

    def pagy_result
      # Apply sorting
      sort_column = params[:sort] || 'created_at'
      sort_direction = params[:direction] || 'desc'
      sorted_payments = @filtered_payments.order("#{sort_column} #{sort_direction}")

      # Pagination
      items_per_page = params[:items]&.to_i || 15
      pagy, paginated_payments = pagy(sorted_payments, items: items_per_page)

      [pagy, paginated_payments]
    end

    def pagy(collection, _options = {})
      # This would typically be handled by the controller
      # For now, we'll return the collection and let the controller handle pagy
      [nil, collection]
    end
  end
end
