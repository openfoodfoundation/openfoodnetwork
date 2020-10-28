module Spree
  module Admin
    class PaymentMethodsController < ResourceController
      skip_before_action :load_resource, only: [:create, :show_provider_preferences]
      before_action :load_data
      before_action :validate_payment_method_provider, only: [:create]
      before_action :load_hubs, only: [:new, :edit, :update]
      create.before :load_hubs

      respond_to :html

      def create
        force_environment

        @payment_method = params[:payment_method].
          delete(:type).
          constantize.
          new(payment_method_params)
        @object = @payment_method

        invoke_callbacks(:create, :before)
        if @payment_method.save
          invoke_callbacks(:create, :after)
          flash[:success] = Spree.t(:successfully_created, resource: Spree.t(:payment_method))
          redirect_to spree.edit_admin_payment_method_path(@payment_method)
        else
          invoke_callbacks(:create, :fails)
          respond_with(@payment_method)
        end
      end

      def update
        restrict_stripe_account_change
        force_environment

        invoke_callbacks(:update, :before)
        payment_method_type = params[:payment_method].delete(:type)
        if @payment_method['type'].to_s != payment_method_type
          @payment_method.update_column(:type, payment_method_type)
          @payment_method = PaymentMethod.find(params[:id])
        end

        if @payment_method.update(params_for_update)
          invoke_callbacks(:update, :after)
          flash[:success] = Spree.t(:successfully_updated, resource: Spree.t(:payment_method))
          redirect_to spree.edit_admin_payment_method_path(@payment_method)
        else
          invoke_callbacks(:update, :fails)
          respond_with(@payment_method)
        end
      end

      # Only show payment methods that user has access to and sort by distributor name
      # ! Redundant code copied from Spree::Admin::ResourceController with modifications marked
      def collection
        return parent.public_send(controller_name) if parent_data.present?

        collection = if model_class.respond_to?(:accessible_by) &&
                        !current_ability.has_block?(params[:action], model_class)

                       model_class.accessible_by(current_ability, action)

                     else
                       model_class.where(nil)
                     end

        collection = collection.managed_by(spree_current_user).by_name # This line added

        # This block added
        if params.key? :enterprise_id
          distributor = Enterprise.find params[:enterprise_id]
          collection = collection.for_distributor(distributor)
        end

        collection
      end

      def show_provider_preferences
        if params[:pm_id].present?
          @payment_method = PaymentMethod.find(params[:pm_id])
          authorize! :show_provider_preferences, @payment_method
          payment_method_type = params[:provider_type]
          if @payment_method['type'].to_s != payment_method_type
            @payment_method.update_column(:type, payment_method_type)
            @payment_method = PaymentMethod.find(params[:pm_id])
          end
        else
          @payment_method = params[:provider_type].constantize.new
        end
        render partial: 'provider_settings'
      end

      private

      def payment_method_params
        params.require(:payment_method).permit(
          :name, :description, :type, :active,
          :environment, :display_on, :tag_list,
          :preferred_enterprise_id, :preferred_server, :preferred_login, :preferred_password,
          :calculator_type, :preferred_api_key,
          :preferred_signature, :preferred_solution, :preferred_landing_page, :preferred_logourl,
          :preferred_test_mode, distributor_ids: []
        )
      end

      def force_environment
        params[:payment_method][:environment] = Rails.env unless spree_current_user.admin?
      end

      def load_data
        @providers = if spree_current_user.admin? || Rails.env.test?
                       Gateway.providers.sort_by(&:name)
                     else
                       Gateway.providers.reject{ |p| p.name.include? "Bogus" }.sort_by(&:name)
                     end
        @providers.reject!{ |provider| stripe_provider?(provider) } unless show_stripe?
        @calculators = PaymentMethod.calculators.sort_by(&:name)
      end

      def validate_payment_method_provider
        valid_payment_methods = Rails.application.config.spree.payment_methods.map(&:to_s)
        return if valid_payment_methods.include?(params[:payment_method][:type])

        flash[:error] = Spree.t(:invalid_payment_provider)
        redirect_to spree.new_admin_payment_method_path
      end

      def load_hubs
        # rubocop:disable Style/TernaryParentheses
        @hubs = Enterprise.managed_by(spree_current_user).is_distributor.sort_by! do |d|
          [(@payment_method.has_distributor? d) ? 0 : 1, d.name]
        end
        # rubocop:enable Style/TernaryParentheses
      end

      # Show Stripe as an option if enabled, or if the
      # current payment_method is already a Stripe method
      def show_stripe?
        Spree::Config.stripe_connect_enabled ||
          stripe_payment_method?
      end

      def restrict_stripe_account_change
        return unless @payment_method
        return unless stripe_payment_method?
        return unless @payment_method.preferred_enterprise_id.andand > 0

        @stripe_account_holder = Enterprise.find(@payment_method.preferred_enterprise_id)
        return if spree_current_user.enterprises.include? @stripe_account_holder

        params[:payment_method][:preferred_enterprise_id] = @stripe_account_holder.id
      end

      def stripe_payment_method?
        ["Spree::Gateway::StripeConnect",
         "Spree::Gateway::StripeSCA"].include? @payment_method.try(:type)
      end

      def stripe_provider?(provider)
        provider.name.ends_with?("StripeConnect", "StripeSCA")
      end

      # Merge payment method params with gateway params like :gateway_stripe_connect
      # Also, remove password if present and blank
      def params_for_update
        gateway_params = params[ActiveModel::Naming.param_key(@payment_method)] || {}
        params_for_update = payment_method_params.merge(gateway_params)

        params_for_update.each do |key, _value|
          if key.include?("password") && params_for_update[key].blank?
            params_for_update.delete(key)
          end
        end

        params_for_update
      end
    end
  end
end
