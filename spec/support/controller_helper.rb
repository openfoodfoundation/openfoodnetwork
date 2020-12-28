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
  end
end
