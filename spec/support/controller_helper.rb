# frozen_string_literal: true

module OpenFoodNetwork
  module ControllerHelper
    def controller_login_as_admin
      @admin_user ||= create(:admin_user)

      allow(controller).to receive_messages(spree_current_user: @admin_user)
    end

    def controller_login_as_enterprise_user(enterprises)
      @enterprise_user ||= begin
        user = create(:user)
        enterprises.each do |enterprise|
          enterprise.enterprise_roles.create!(user:)
        end
        user
      end

      allow(controller).to receive_messages(spree_current_user: @enterprise_user)
    end
  end
end
