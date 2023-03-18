# frozen_string_literal: true

module Spree
  module Admin
    class PaymentMethodsController < ::Admin::ResourceController
      skip_before_action :load_resource, only: [:create, :show_provider_preferences]
      before_action :load_data
      before_action :validate_payment_method_provider, only: [:create]
      before_action :load_hubs, only: [:new, :edit, :update]

      respond_to :html

      def create
        force_environment

        @payment_method = payment_method_class.constantize.new(base_params)
        @object = @payment_method

        if !base_params["calculator_type"] && gateway_params["calculator_type"]
          @payment_method.calculator_type = gateway_params["calculator_type"]
        end

        load_hubs

        if @payment_method.save
          flash[:success] = Spree.t(:successfully_created, resource: Spree.t(:payment_method))
          redirect_to spree.edit_admin_payment_method_path(@payment_method)
        else
          respond_with(@payment_method)
        end
      end

      def update
        restrict_stripe_account_change
        force_environment

        if @payment_method.type.to_s != payment_method_class
          @payment_method.update_columns(
            type: payment_method_class,
            updated_at: Time.zone.now
          )
          @payment_method = PaymentMethod.find(params[:id])
        end

        if @payment_method.update(update_params)
          flash[:success] = Spree.t(:successfully_updated, resource: Spree.t(:payment_method))
          redirect_to spree.edit_admin_payment_method_path(@payment_method)
        else
          respond_with(@payment_method)
          clear_preference_cache
        end
      end

      # Only show payment methods that user has access to and sort by distributor name
      # ! Redundant code copied from Admin::ResourceController with modifications marked
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
            @payment_method.update_columns(
              type: payment_method_type,
              updated_at: Time.zone.now
            )
            @payment_method = PaymentMethod.find(params[:pm_id])
          end
        else
          @payment_method = params[:provider_type].constantize.new
        end
        render partial: 'provider_settings'
      end

      private

      def payment_method_class
        @payment_method_class ||= base_params.delete(:type)
      end

      def force_environment
        base_params[:environment] = Rails.env unless spree_current_user.admin?
      end

      def load_data
        @providers = load_providers
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
        @hubs = Enterprise.managed_by(spree_current_user).is_distributor.to_a.sort_by! do |d|
          [(@payment_method.has_distributor? d) ? 0 : 1, d.name]
        end
        # rubocop:enable Style/TernaryParentheses
      end

      def load_providers
        providers = Gateway.providers.sort_by(&:name)

        unless Rails.env.development? || Rails.env.test?
          providers.reject! { |provider| provider.name.include? "Bogus" }
        end

        unless show_stripe?
          providers.reject! { |provider| stripe_provider?(provider) }
        end

        providers
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
        return unless @payment_method.preferred_enterprise_id&.positive?

        @stripe_account_holder = Enterprise.find(@payment_method.preferred_enterprise_id)
        return if spree_current_user.enterprises.include? @stripe_account_holder

        update_params[:preferred_enterprise_id] = @stripe_account_holder.id
      end

      def stripe_payment_method?
        @payment_method.try(:type) == "Spree::Gateway::StripeSCA"
      end

      def stripe_provider?(provider)
        provider.name.ends_with?("StripeSCA")
      end

      def base_params
        @base_params ||= PermittedAttributes::PaymentMethod.new(params[:payment_method]).
          call.to_h.with_indifferent_access
      end

      def gateway_params
        raw_params[ActiveModel::Naming.param_key(@payment_method)] || {}
      end

      # Merge payment method params with gateway params like :gateway_stripe_sca
      # Also, remove password if present and blank
      def update_params
        @update_params ||= begin
          params_for_update = base_params.merge(gateway_params)

          params_for_update.each do |key, value|
            if key.include?("password") && value.blank?
              params_for_update.delete(key)
            end
          end

          # Ensure the calculator to be updated is the correct type
          if params_for_update["calculator_type"] && params_for_update["calculator_attributes"]
            add_type_to_calculator_attributes(params_for_update)
          end

          params_for_update
        end
      end

      def clear_preference_cache
        @payment_method.calculator.preferences.each_key do |key|
          Rails.cache.delete(@payment_method.calculator.preference_cache_key(key))
        end
      end

      def add_type_to_calculator_attributes(hash)
        hash["calculator_attributes"]["type"] = hash["calculator_type"]
      end
    end
  end
end
