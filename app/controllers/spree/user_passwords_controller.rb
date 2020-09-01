# frozen_string_literal: true

require "spree/core/controller_helpers/auth"
require "spree/core/controller_helpers/common"
require "spree/core/controller_helpers/order"
require "spree/core/controller_helpers/ssl"

module Spree
  class UserPasswordsController < Devise::PasswordsController
    helper 'spree/base'

    include Spree::Core::ControllerHelpers::Auth
    include Spree::Core::ControllerHelpers::Common
    include Spree::Core::ControllerHelpers::Order
    include Spree::Core::ControllerHelpers::SSL

    ssl_required

    # Overridden due to bug in Devise.
    #   respond_with resource, :location => new_session_path(resource_name)
    # is generating bad url /session/new.user
    #
    # overridden to:
    #   respond_with resource, :location => spree.login_path
    #
    def create
      self.resource = resource_class.send_reset_password_instructions(params[resource_name])

      if resource.errors.empty?
        set_flash_message(:notice, :send_instructions) if is_navigational_format?
        respond_with resource, location: spree.login_path
      else
        respond_with_navigational(resource) { render :new }
      end
    end

    # Devise::PasswordsController allows for blank passwords.
    # Silly Devise::PasswordsController!
    # Fixes spree/spree#2190.
    def update
      if params[:spree_user][:password].blank?
        self.resource = resource_class.new
        resource.reset_password_token = params[:spree_user][:reset_password_token]
        set_flash_message(:error, :cannot_be_blank)
        render :edit
      else
        super
      end
    end
  end
end
