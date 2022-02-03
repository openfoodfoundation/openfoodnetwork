# frozen_string_literal: true

require "spree/core/controller_helpers/auth"
require "spree/core/controller_helpers/common"
require "spree/core/controller_helpers/order"

module Spree
  class UserPasswordsController < Devise::PasswordsController
    helper 'spree/base'

    include RawParams
    include Spree::Core::ControllerHelpers::Auth
    include Spree::Core::ControllerHelpers::Common
    include Spree::Core::ControllerHelpers::Order

    include I18nHelper
    before_action :set_locale

    # Devise::PasswordsController allows for blank passwords.
    # Silly Devise::PasswordsController!
    # Fixes spree/spree#2190.
    def update
      if params.dig(:spree_user, :password).blank?
        self.resource = resource_class.new
        resource.reset_password_token = params.dig(:spree_user, :reset_password_token)
        set_flash_message(:error, :cannot_be_blank)
        render :edit
      else
        super
      end
    end
  end
end
