# frozen_string_literal: true

module Admin
  module Members
    module UpdateHandling
      extend ActiveSupport::Concern

      USER_UPDATE_CONTROL_KEYS = %i[email_address system_role created_by_admin create_web_account].freeze

      private

      def handle_member_update
        return handle_person_update if @person.user.nil?

        handle_user_update
      end

      def handle_person_update
        result = build_person_update_result(@person)

        return respond_to_successful_person_update(result.person || @person) if result.success?
        return respond_to_failed_person_update(result) unless request.xhr?

        render json: { success: false, errors: result.errors }, status: :unprocessable_content
      end

      def handle_user_update
        respond_to do |format|
          result = build_user_update_result
          result.success? ? respond_to_successful_user_update(format) : respond_to_failed_user_update(format, result)
        end
      end

      def build_person_update_result(person)
        person_attributes = person_params.to_h.deep_symbolize_keys
        newsletter_flag = ActiveModel::Type::Boolean.new.cast(person_attributes.delete(:newsletter_subscribed))

        People::Register.new(
          person_params: person_attributes.merge(allow_blank_attributes: true),
          existing_person: person,
          newsletter_subscribed: newsletter_flag,
          newsletter_source: "admin",
          create_user_account: false,
          create_membership: false
        ).call
      end

      def respond_to_successful_person_update(person)
        if request.xhr?
          render json: {
            success: true,
            member_number: person.reload.member_number,
            message: t(".ajax_success_json_message")
          }
        else
          redirect_to admin_member_path(person), notice: t(".person_saved_notice")
        end
      end

      def respond_to_failed_person_update(result)
        flash.now[:alert] = result.message
        render :edit_person, status: :unprocessable_content
      end

      def build_user_update_result
        user_only_params, person_params_flat, newsletter_subscribed_value = extracted_member_update_attributes

        UserManagement::UserUpdater.new(
          user_id: @person.user.id,
          email_address: user_only_params[:email_address],
          system_role: user_only_params[:system_role],
          person_attributes: person_params_flat,
          newsletter_subscribed: newsletter_subscribed_value,
          updated_by_id: Current.user.id
        ).call
      end

      def extracted_member_update_attributes
        permitted_params = member_params
        user_only_params = permitted_params.slice(*USER_UPDATE_CONTROL_KEYS)
        person_params_flat = permitted_params.except(*USER_UPDATE_CONTROL_KEYS, :person)
        newsletter_subscribed_value = extract_newsletter_subscribed!(
          source_params: permitted_params,
          person_params: person_params_flat
        )

        [ user_only_params, person_params_flat, newsletter_subscribed_value ]
      end

      def respond_to_successful_user_update(format)
        format.html { redirect_to admin_member_path(@person), notice: t(".html_updated") }
        format.json { render json: @person }
        format.turbo_stream do
          flash.now[:notice] = t(".turbo_notice")
          render turbo_stream: [
            turbo_stream.replace(@person),
            turbo_stream.replace("flash", partial: "shared/flash")
          ]
        end
      end

      def respond_to_failed_user_update(format, result)
        format.html { render :show, status: :unprocessable_content, alert: result.message }
        format.json { render json: { errors: result.errors }, status: :unprocessable_content }
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "error_explanation",
            partial: "shared/error_messages",
            locals: { resource: @person, errors: result.errors }
          )
        end
      end
    end
  end
end
