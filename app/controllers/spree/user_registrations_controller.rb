# frozen_string_literal: true

require "spree/core/controller_helpers/auth"
require "spree/core/controller_helpers/common"
require "spree/core/controller_helpers/order"
require "spree/core/controller_helpers/ssl"

module Spree
  class UserRegistrationsController < Devise::RegistrationsController
    helper 'spree/base'

    include Spree::Core::ControllerHelpers::Auth
    include Spree::Core::ControllerHelpers::Common
    include Spree::Core::ControllerHelpers::Order
    include Spree::Core::ControllerHelpers::SSL

    ssl_required
    before_action :check_permissions, only: [:edit, :update]
    skip_before_action :require_no_authentication

    # GET /resource/sign_up
    def new
      super
      @user = resource
    end

    # POST /resource/sign_up
    def create
      @user = build_resource(params[:spree_user])
      if resource.save
        set_flash_message(:notice, :signed_up)
        sign_in(:spree_user, @user)
        associate_user
        respond_with resource, location: after_sign_up_path_for(resource)
      else
        clean_up_passwords(resource)
        render :new
      end
    end

    # GET /resource/edit
    def edit
      super
    end

    # PUT /resource
    def update
      super
    end

    # DELETE /resource
    def destroy
      super
    end

    # GET /resource/cancel
    # Forces the session data which is usually expired after sign
    # in to be expired now. This is useful if the user wants to
    # cancel oauth signing in/up in the middle of the process,
    # removing all OAuth session data.
    def cancel
      super
    end

    protected

    def check_permissions
      authorize!(:create, resource)
    end
  end
end
