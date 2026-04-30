# frozen_string_literal: true

# Polymorphic ActiveRecord class for +PaymentLine+ rows with +item_type: "Donation"+.
#
# There is no +donations+ table: +item_id+ references the parent transaction row in +payments+
# (see +People::PaymentCreator+). Subclassing +Payment+ lets +includes(:item)+ and +PaymentLine#item+
# work without schema changes.
class Donation < Payment
  self.table_name = "payments"
  # +payments+ has no STI +type+ column; keep subclass reads/writes on the same table.
  self.inheritance_column = nil
end
