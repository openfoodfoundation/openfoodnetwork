module Spree
  module AuthenticationHelpers
    def self.included(receiver)
      receiver.public_send :helper_method, :spree_current_user
      receiver.public_send :helper_method, :spree_login_path
      receiver.public_send :helper_method, :spree_signup_path
      receiver.public_send :helper_method, :spree_logout_path
    end

    def spree_current_user
      current_spree_user
    end

    delegate :login_path, to: :spree, prefix: true

    delegate :signup_path, to: :spree, prefix: true

    delegate :logout_path, to: :spree, prefix: true
  end
end
