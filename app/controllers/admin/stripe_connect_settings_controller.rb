# frozen_string_literal: true

# This controller is used by super admin users to update the settings the app is using

module Admin
  class StripeConnectSettingsController < Spree::Admin::BaseController
    StripeConnectSettings = Struct.new(:stripe_connect_enabled)

    before_action :load_settings, only: [:edit]

    def edit
      return @stripe_account = { status: :empty_api_key_error_html } if Stripe.api_key.blank?

      attrs = %i[id business_name charges_enabled]
      @obfuscated_secret_key = obfuscated_secret_key
      @stripe_account = Stripe::Account.retrieve.to_hash.slice(*attrs).merge(status: :ok)
    rescue Stripe::AuthenticationError
      @stripe_account = { status: :auth_fail_error }
    end

    def update
      Spree::Config.set(settings_params.to_h)
      resource = t('admin.controllers.stripe_connect_settings.resource')
      flash[:success] = t(:successfully_updated, resource:)
      redirect_to_edit
    end

    private

    def load_settings
      @settings = StripeConnectSettings.new(Spree::Config[:stripe_connect_enabled])
    end

    def redirect_to_edit
      redirect_to main_app.edit_admin_stripe_connect_settings_path
    end

    def obfuscated_secret_key
      key = Stripe.api_key
      "#{key.first(8)}****#{key.last(4)}"
    end

    def settings_params
      params.require(:settings).permit(
        :stripe_connect_enabled,
      )
    end
  end
end
