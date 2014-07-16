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
  end
end
