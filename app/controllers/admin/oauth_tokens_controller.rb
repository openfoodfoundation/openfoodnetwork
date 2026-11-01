# frozen_string_literal: true

module Admin
  # Super admins review the access tokens granted to OAuth applications and
  # revoke them. Revoking keeps the history and also kills the refresh token.
  class OauthTokensController < Spree::Admin::BaseController
    def index
      @applications = Doorkeeper::Application.order(:name)
      @pagy, @tokens = pagy(filtered_tokens, limit: 50)
      @users = Spree::User.where(id: @tokens.map(&:resource_owner_id)).index_by(&:id)
    end

    def revoke
      Doorkeeper::AccessToken.find(params[:id]).revoke
      flash[:success] = t(".success")
      redirect_back_or_to main_app.admin_oauth_tokens_path
    end

    private

    def filtered_tokens
      tokens = Doorkeeper::AccessToken.includes(:application).order(created_at: :desc)
      tokens = tokens.where(revoked_at: nil) unless params[:revoked] == "1"
      if params[:application_id].present?
        tokens = tokens.where(application_id: params[:application_id])
      end
      tokens
    end
  end
end
