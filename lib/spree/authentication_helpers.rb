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

    def spree_login_path
      spree.login_path
    end

    def spree_signup_path
      spree.signup_path
    end

    def spree_logout_path
      spree.logout_path
    end
  end
end
