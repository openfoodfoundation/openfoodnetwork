# frozen_string_literal: true

module Admin
  class UserInvitationsController < ResourceController
    before_action :load_enterprise

    def new; end

    def create
      @user_invitation.attributes = permitted_resource_params
      if @user_invitation.save
        flash[:success] = I18n.t(:user_invited, email: @user_invitation.email)
      else
        render :new
      end
    end

    private

    def load_enterprise
      @enterprise = OpenFoodNetwork::Permissions
        .new(spree_current_user)
        .editable_enterprises
        .find_by(permalink: params[:enterprise_id])
    end

    def permitted_resource_params
      params.require(:user_invitation).permit(:email).merge(enterprise: @enterprise)
    end
  end
end
