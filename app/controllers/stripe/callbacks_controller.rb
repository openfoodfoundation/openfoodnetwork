# frozen_string_literal: true

require 'stripe/account_connector'

module Stripe
  class CallbacksController < BaseController
    # GET /stripe/callbacks
    def index
      connector = Stripe::AccountConnector.new(spree_current_user, params)

      if connector.create_account
        flash[:success] = t('admin.controllers.enterprises.stripe_connect_success')
      elsif connector.connection_cancelled_by_user?
        flash[:notice] = t('admin.controllers.enterprises.stripe_connect_cancelled')
      else
        flash[:error] = t('admin.controllers.enterprises.stripe_connect_fail')
      end
      redirect_to main_app.edit_admin_enterprise_path(connector.enterprise,
                                                      anchor: 'payment_methods')
    rescue Stripe::StripeError => e
      render plain: e.message, status: :internal_server_error
    end
  end
end
