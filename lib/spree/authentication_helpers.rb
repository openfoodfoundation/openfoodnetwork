# frozen_string_literal: true

module Spree
  module AuthenticationHelpers
    def self.included(receiver)
      receiver.public_send :helper_method, :spree_current_user
      receiver.public_send :helper_method, :spree_login_path
      receiver.public_send :helper_method, :spree_logout_path
    end

    def spree_current_user
      current_spree_user
    end

    def spree_login_path
      main_app.login_path
    end

    delegate :logout_path, to: :spree, prefix: true
  end
end
