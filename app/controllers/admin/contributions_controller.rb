# frozen_string_literal: true

module Admin
  class ContributionsController < BaseController
    PURCHASE_ATTRS = %i[
      contribution_formula_id
      payment_method
      record_attendance
      attendance_date
      custom_amount_cents
      offer_reason
      donation_amount
    ].freeze

    before_action :set_person, only: %i[create upgrade]
    before_action :set_person_for_new, only: %i[new beneficiary_search]
    before_action :set_breadcrumbs, only: %i[new create]

    def new
      unless @person
        redirect_to admin_members_path, alert: t(".person_required_alert") and return
      end

      unless @person.can_buy_contribution_formulas?
        flash[:alert] = t(".needs_circus_membership_alert")
        redirect_to admin_person_path(@person)
        return
      end

      @contribution_formulas = ContributionFormula.available_for(@person)
    end

    def create
      custom_amount = (contribution_purchase_params[:custom_amount_cents].to_i if contribution_purchase_params[:payment_method] == "offered")
      donation_cents = donation_cents_from(contribution_purchase_params)

      result = People::ContributionCreator.new(
        person: @person,
        contribution_formula_id: contribution_purchase_params[:contribution_formula_id],
        payment_method: contribution_purchase_params[:payment_method].presence || "cash",
        recorded_by_id: Current.user&.id,
        record_attendance: ActiveModel::Type::Boolean.new.cast(contribution_purchase_params[:record_attendance]),
        beneficiaries: build_beneficiary_entries,
        custom_amount_cents: custom_amount,
        offer_reason: contribution_purchase_params[:offer_reason],
        donation_cents: donation_cents
      ).call

      if result.success?
        redirect_to admin_person_path(@person), notice: purchase_notice_with_warnings(result)
      else
        redirect_to new_admin_contribution_path(person_id: @person.id),
                    alert: t(".purchase_failed_alert", message: result.message)
      end
    rescue StandardError => e
      flash[:alert] = t(".purchase_failed_alert", message: e.message)
      redirect_to new_admin_contribution_path(person_id: @person.id)
    end

    def beneficiary_search
      exclude_ids = Array(params[:exclude_ids]).map(&:to_i)
      exclude_ids << @person.id if @person

      # Garde-fou : seules les personnes avec une adhésion Cirque active peuvent
      # bénéficier d'une cotisation — ne pas les proposer évite un rejet après coup.
      @candidates = PersonNameSearch.call(query: params[:q], exclude_ids: exclude_ids)
                                     .merge(Person.eligible_for_contribution_formulas)

      render partial: "admin/contributions/beneficiary_search_results", locals: { candidates: @candidates }
    end

    def upgrade
      result = build_contribution_upgrader.call

      if result.success?
        redirect_to admin_person_path(@person), notice: upgrade_notice_for(result)
      else
        redirect_to admin_person_path(@person), alert: upgrade_failure_message(result.message)
      end
    rescue StandardError => e
      redirect_to admin_person_path(@person), alert: upgrade_failure_message(e.message)
    end

    private

    def set_person
      @person = Person.find(params[:person_id])
    end

    def set_person_for_new
      @person = Person.find(params[:person_id]) if params[:person_id].present?
    end

    def set_breadcrumbs
      add_breadcrumb I18n.t("breadcrumbs.admin.common.administration"), admin_dashboard_index_path
      add_person_context_breadcrumbs(@person, I18n.t("breadcrumbs.admin.contributions.new_contribution")) if @person.present?
    end

    def admin_person_path(person)
      admin_member_path(person)
    end

    # La présence est enregistrée en best-effort (cf. People::ContributionCreator) : la
    # cotisation reste valable même si la présence échoue (jour fermé, déjà présent...).
    # On ne veut plus que ça disparaisse silencieusement pour autant — on l'ajoute au notice.
    def purchase_notice_with_warnings(result)
      return t(".purchased") if result.attendance_warnings.blank?

      "#{t('.purchased')} #{t('.attendance_not_recorded_warning', details: result.attendance_warnings.join(' · '))}"
    end

    def contribution_purchase_params
      params.expect(contribution: PURCHASE_ATTRS).merge(recorded_by_id: Current.user.id)
    end

    # `contribution[beneficiaries][0][person_id]`, etc. — le formulaire utilise un index
    # numérique explicite par ligne (nécessaire pour que les boutons radio "formule" de
    # chaque bénéficiaire ne se regroupent pas entre eux). Rails/Rack parse alors
    # `beneficiaries` comme un Hash `{"0" => {...}, "1" => {...}}`, PAS comme un Array —
    # `params.expect(beneficiaries: [[...]])` exige strictement un Array et échouait donc
    # silencieusement sur toute soumission réelle (voir incident : bénéficiaire ignoré sans
    # erreur visible). On lit et on permit chaque entrée à la main plutôt que via `expect`.
    def raw_beneficiary_params
      raw = params.dig(:contribution, :beneficiaries)
      return [] if raw.blank?

      # Chaque entrée n'est jamais utilisée que pour lire person_id/contribution_formula_id/
      # record_attendance (jamais de mass-assignment sur un modèle) : to_unsafe_h suffit ici,
      # même patron que People::PaymentRecorder#normalize_payment_lines.
      raw.to_unsafe_h.values
    end

    # nil si aucun bénéficiaire additionnel n'a été soumis : People::ContributionCreator
    # retombe alors sur son chemin single-bénéficiaire historique (achat pour @person
    # uniquement). Une ligne bénéficiaire soumise SANS person_id est en revanche une
    # anomalie (jamais un cas normal, cf. incident où une personne payait sans que le
    # bénéficiaire ne reçoive rien, silencieusement) : on échoue bruyamment plutôt que
    # de l'ignorer et de facturer un montant différent de ce que l'admin avait sous les yeux.
    def build_beneficiary_entries
      raw = raw_beneficiary_params
      return nil if raw.blank?

      if raw.any? { |beneficiary| beneficiary[:person_id].blank? }
        raise "Un bénéficiaire additionnel n'a pas de personne sélectionnée dans le formulaire — rien n'a été enregistré, merci de réessayer."
      end

      payer_entry = {
        person: @person,
        contribution_formula_id: contribution_purchase_params[:contribution_formula_id],
        record_attendance: ActiveModel::Type::Boolean.new.cast(contribution_purchase_params[:record_attendance])
      }

      [ payer_entry ] + raw.map do |beneficiary|
        {
          person: Person.find(beneficiary[:person_id]),
          contribution_formula_id: beneficiary[:contribution_formula_id],
          record_attendance: ActiveModel::Type::Boolean.new.cast(beneficiary[:record_attendance])
        }
      end
    end

    def donation_cents_from(params_hash)
      return nil if params_hash[:donation_amount].blank?

      cents = (params_hash[:donation_amount].to_f * 100).to_i
      cents.positive? ? cents : nil
    end

    def build_contribution_upgrader
      People::ContributionUpgrader.new(
        person: @person,
        from_contribution_id: source_contribution_id,
        to_formula_id: target_formula_id,
        payment_method: params[:payment_method].presence || "cash",
        recorded_by_id: Current.user.id,
        offer_reason: params[:offer_reason]
      )
    end

    def source_contribution_id
      params[:from_contribution_id].presence || params[:from_book_id]
    end

    def target_formula_id
      params[:to_formula_id].presence || params[:to_plan_id]
    end

    def upgrade_notice_for(result)
      return t(".success_notice") unless result.credit_applied.positive?

      t(".success_notice") + t(".credit_applied_suffix", amount: (result.credit_applied / 100.0).round(2))
    end

    def upgrade_failure_message(message)
      t(".failure_alert", message: message)
    end
  end
end
