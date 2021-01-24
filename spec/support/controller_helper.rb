# frozen_string_literal: true

module OpenFoodNetwork
  module ControllerHelper
    def controller_login_as_admin
      @admin_user ||= begin
        user = create(:user)
        user.spree_roles << Spree::Role.find_or_create_by!(name: 'admin')
        user
      end

      allow(controller).to receive_messages(spree_current_user: @admin_user)
    end

    def controller_login_as_enterprise_user(enterprises)
      @enterprise_user ||= begin
        user = create(:user)
        user.spree_roles = []
        enterprises.each do |enterprise|
          enterprise.enterprise_roles.create!(user: user)
        end
        user
      end

      allow(controller).to receive_messages(spree_current_user: @enterprise_user)
    end

    def reset_controller_environment
      # Rails 5.0 introduced a bug in controller tests (fixed in 5.2) where the controller's
      # environment is essentially cached if multiple requests are made in the same `it` block,
      # meaning subsequent requests will not be handled well. This resets the environment.
      # This edge case is quite rare though; normally we only do one request per test.
      @request.env.delete("RAW_POST_DATA")
    end
  end
end
