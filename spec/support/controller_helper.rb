module OpenFoodNetwork
  module ControllerHelper
    def login_as_admin
      @admin_user ||= begin
        user = create(:user)
        user.spree_roles << Spree::Role.find_or_create_by_name!('admin')
        user
      end

      controller.stub spree_current_user: @admin_user
    end

    def login_as_enterprise_user(enterprises)
      @enterprise_user ||= begin
        user = create(:user)
        user.spree_roles = []
        enterprises.each do |enterprise|
          enterprise.enterprise_roles.create!(user: user)
        end
        user
      end

      controller.stub spree_current_user: @enterprise_user
    end
  end
end
