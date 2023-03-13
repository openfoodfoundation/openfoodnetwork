# frozen_string_literal: true

module Admin
  class ManagerInvitationsController < Spree::Admin::BaseController
    authorize_resource class: false
    include ManagerInvitations

    def create
      @email = params[:email]
      @enterprise = Enterprise.find(params[:enterprise_id])

      authorize! :edit, @enterprise

      existing_user = Spree::User.find_by(email: @email)

      if existing_user
        render json: { errors: t('admin.enterprises.invite_manager.user_already_exists') },
               status: :unprocessable_entity
        return
      end

      new_user = create_new_manager(@email, @enterprise)

      if new_user
        render json: { user: new_user.id }, status: :ok
      else
        render json: { errors: t('admin.enterprises.invite_manager.error') },
               status: :internal_server_error
      end
    end
  end
end
