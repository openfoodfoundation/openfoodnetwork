# frozen_string_literal: true

require 'stripe/account_connector'

module Admin
  class StripeAccountsController < Spree::Admin::BaseController
    def connect
      payload = params.permit(:enterprise_id).to_h
      key = Openfoodnetwork::Application.config.secret_token
      url_params = { state: JWT.encode(payload, key, 'HS256'), scope: "read_write" }
      redirect_to Stripe::OAuth.authorize_url(url_params)
    end

    def destroy
      stripe_account = StripeAccount.find(params[:id])
      authorize! :destroy, stripe_account

      if stripe_account.deauthorize_and_destroy
        flash[:success] = "Stripe account disconnected."
      else
        flash[:error] = "Failed to disconnect Stripe."
      end

      redirect_to main_app.edit_admin_enterprise_path(stripe_account.enterprise)
    rescue ActiveRecord::RecordNotFound
      flash[:error] = "Failed to disconnect Stripe."
      redirect_to spree.admin_dashboard_path
    end

    def status
      return render json: { status: :stripe_disabled } unless Spree::Config.stripe_connect_enabled

      stripe_account = StripeAccount.find_by(enterprise_id: params[:enterprise_id])
      return render json: { status: :account_missing } unless stripe_account

      authorize! :status, stripe_account

      begin
        status = Stripe::Account.retrieve(stripe_account.stripe_user_id)
        attrs = %i[id business_name charges_enabled]
        render json: status.to_hash.slice(*attrs).merge( status: :connected)
      rescue Stripe::APIError
        render json: { status: :access_revoked }
      end
    end

    private

    def model_class
      StripeAccount
    end
  end
end
