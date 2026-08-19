# frozen_string_literal: true

require "rails_helper"

RSpec.describe Imports::MemberImportService do
  let!(:admin) { create(:user, :admin) }
  let!(:membership_type) { create(:membership_type, category: :circus, price_cents: 1000, effective_until: nil) }

  let(:header) { "N°,N° adhérent,Nom,Prénom,Naissance,Adresse,CP,Ville,Téléphone,Email,Profession,Spécialité,Droit image,Newsletter,Implication,Montant,Méthode,Date paiement" }

  def csv_row(member_number: "25C001", last_name: "Dupont", first_name: "Alice", amount: "10")
    [
      "1", member_number, last_name, first_name, "01/01/1990", "1 rue Test", "31000", "Toulouse",
      "0600000000", "alice@example.test", "", "", "non", "non", "non", amount, "Espèces", "10/08/2025"
    ].join(",")
  end

  it "creates an initial member_number_histories entry so imported members are traceable from the start" do
    csv = "#{header}\n#{csv_row}"

    result = described_class.new(csv_content: csv).call

    expect(result.success?).to be(true)
    expect(result.created_count).to eq(1)

    person = Person.find_by(member_number: "25C001")
    expect(person).to be_present

    history = person.member_number_histories.sole
    expect(history.member_number).to eq("25C001")
    expect(history.membership_type).to eq("Cirque")
    expect(history.year).to eq(2025)
    expect(history.notes).to include("import CSV")
    expect(history.replaced_at).to be_nil
  end

  it "does not create a history entry when the row has no member_number" do
    csv = "#{header}\n#{csv_row(member_number: '')}"

    result = described_class.new(csv_content: csv).call

    expect(result.success?).to be(true)
    person = Person.find_by(first_name: "Alice", last_name: "Dupont")
    expect(person.member_number).to be_blank
    expect(person.member_number_histories).to be_empty
  end
end
