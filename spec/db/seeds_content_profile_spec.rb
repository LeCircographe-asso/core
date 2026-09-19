# frozen_string_literal: true

require "rails_helper"

# Garantit qu'un `db:seed` (lancé au premier boot d'une base fraîche par `db:prepare`,
# ou à la main) ne peut jamais effacer ni polluer une base de production.
RSpec.describe "db/seeds.rb content-only profile (staging / production)" do
  def run_seeds_as(env_name)
    allow(Rails).to receive(:env).and_return(ActiveSupport::EnvironmentInquirer.new(env_name))
    # Les constantes SEED_* sont redéfinies à chaque chargement : on masque l'avertissement Ruby.
    silence_warnings { capture_stdout { load Rails.root.join("db/seeds.rb") } }
  end

  def capture_stdout
    original = $stdout
    $stdout = StringIO.new
    yield
  ensure
    $stdout = original
  end

  %w[production staging].each do |env_name|
    context "in #{env_name}" do
      it "seeds FAQ, board members and partners on an empty database" do
        run_seeds_as(env_name)

        expect(Faq.count).to be_positive
        expect(BoardMember.count).to be_positive
        expect(Partner.count).to be_positive
      end

      it "creates no account and no catalogue entry" do
        run_seeds_as(env_name)

        expect(User.count).to eq(0)
        expect(Person.count).to eq(0)
        expect(MembershipType.count).to eq(0)
        expect(ContributionFormula.count).to eq(0)
        expect(Event.count).to eq(0)
        expect(User.find_by(email_address: "super-admin@rails.com")).to be_nil
      end

      it "never wipes existing business data" do
        member = create(:person)
        membership_type = create(:membership_type)
        existing_faq = Faq.create!(question: "Question saisie en admin ?", answer: "Réponse saisie en admin.")

        run_seeds_as(env_name)

        expect(Person.exists?(member.id)).to be(true)
        expect(MembershipType.exists?(membership_type.id)).to be(true)
        expect(Faq.exists?(existing_faq.id)).to be(true)
      end

      it "leaves a content table untouched once it holds rows, and is idempotent" do
        existing_faq = Faq.create!(question: "Question saisie en admin ?", answer: "Réponse saisie en admin.")

        run_seeds_as(env_name)
        expect(Faq.pluck(:id)).to eq([ existing_faq.id ])
        board_count = BoardMember.count

        run_seeds_as(env_name)
        expect(BoardMember.count).to eq(board_count)
      end
    end
  end

  it "refuses to run the demo profile in production" do
    stub_const("ENV", ENV.to_h.merge("SEED_DEMO" => "true"))

    expect { run_seeds_as("production") }.to raise_error(Seeds::Profile::DemoSeedInProductionError)
    expect(User.count).to eq(0)
  end
end
