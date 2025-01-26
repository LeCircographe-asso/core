require "test_helper"

class PaymentTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      email_address: "test@example.com",
      first_name: "Test",
      last_name: "User",
      password: "password",
      password_confirmation: "password"
    )
    
    @admin = User.create!(
      email_address: "admin@example.com",
      first_name: "Admin",
      last_name: "User",
      password: "password",
      password_confirmation: "password",
      role: :admin
    )
  end

  test "création d'un paiement valide" do
    payment = Payment.new(
      user: @user,
      amount: 10,
      payment_method: :cash,
      status: :completed,
      recorded_by: @admin
    )
    
    assert payment.valid?
  end

  test "ne peut pas créer de paiement avec un montant négatif" do
    payment = Payment.new(
      user: @user,
      amount: -10,
      payment_method: :cash,
      status: :completed
    )
    
    assert_not payment.valid?
    assert_includes payment.errors[:amount], "must be greater than or equal to 0"
  end

  test "ne peut pas créer de paiement avec un don négatif" do
    payment = Payment.new(
      user: @user,
      amount: 10,
      donation_amount: -5,
      payment_method: :cash,
      status: :completed
    )
    
    assert_not payment.valid?
    assert_includes payment.errors[:donation_amount], "must be greater than or equal to 0"
  end

  test "calcule correctement le montant total avec don" do
    payment = Payment.create!(
      user: @user,
      amount: 10,
      donation_amount: 5,
      payment_method: :cash,
      status: :completed
    )
    
    assert_equal 15, payment.total_amount
  end

  test "initialise le montant du don à 0 si non spécifié" do
    payment = Payment.create!(
      user: @user,
      amount: 10,
      payment_method: :cash,
      status: :completed
    )
    
    assert_equal 0, payment.donation_amount
  end

  test "scope successful retourne uniquement les paiements complétés" do
    completed = Payment.create!(
      user: @user,
      amount: 10,
      payment_method: :cash,
      status: :completed
    )
    
    pending = Payment.create!(
      user: @user,
      amount: 10,
      payment_method: :cash,
      status: :pending
    )
    
    assert_includes Payment.successful, completed
    assert_not_includes Payment.successful, pending
  end

  test "scope with_donation retourne uniquement les paiements avec don" do
    with_donation = Payment.create!(
      user: @user,
      amount: 10,
      donation_amount: 5,
      payment_method: :cash,
      status: :completed
    )
    
    without_donation = Payment.create!(
      user: @user,
      amount: 10,
      payment_method: :cash,
      status: :completed
    )
    
    assert_includes Payment.with_donation, with_donation
    assert_not_includes Payment.with_donation, without_donation
  end

  test "paiement adhésion simple sans don" do
    payment = payments(:completed_simple)
    assert payment.valid?
    assert_equal 1.0, payment.amount
    assert_equal 0, payment.donation_amount
    assert_equal 1.0, payment.total_amount
    assert_not payment.has_donation?
  end

  test "paiement adhésion cirque avec don" do
    payment = payments(:completed_circus)
    assert payment.valid?
    assert_equal 10.0, payment.amount
    assert_equal 5.0, payment.donation_amount
    assert_equal 15.0, payment.total_amount
    assert payment.has_donation?
  end

  test "paiement en attente pour visiteur" do
    payment = payments(:pending_payment)
    assert payment.valid?
    assert_equal "pending", payment.status
    assert_equal "card", payment.payment_method
    assert_nil payment.processed_by
    assert_nil payment.processed_at
  end

  test "paiement bénévole avec don par virement" do
    payment = payments(:completed_volunteer)
    assert payment.valid?
    assert_equal "transfer", payment.payment_method
    assert_equal 2.0, payment.donation_amount
    assert payment.processed_by.present?
  end

  test "paiement carnet 10 séances en espèces" do
    payment = payments(:completed_ten_sessions)
    assert payment.valid?
    assert_equal 45.0, payment.amount
    assert_equal "cash", payment.payment_method
    assert_equal "completed", payment.status
  end

  test "seul un admin peut traiter un paiement" do
    payment = payments(:pending_payment)
    payment.processed_by = users(:volunteer)
    assert_not payment.valid?
    
    payment.processed_by = users(:admin)
    assert payment.valid?
  end

  test "changement de statut cohérent" do
    payment = payments(:pending_payment)
    
    # Peut passer de pending à completed
    payment.status = "completed"
    assert payment.valid?
    
    # Ne peut pas passer directement de completed à refunded sans être completed
    payment = payments(:pending_payment)
    payment.status = "refunded"
    assert_not payment.valid?
  end

  test "méthodes de paiement autorisées" do
    payment = Payment.new(
      user: users(:simple_member),
      amount: 10,
      payment_method: "invalid"
    )
    assert_not payment.valid?
    
    Payment.payment_methods.keys.each do |method|
      payment.payment_method = method
      assert payment.valid?, "#{method} devrait être une méthode de paiement valide"
    end
  end
end
