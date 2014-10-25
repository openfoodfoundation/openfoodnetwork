Devise::ConfirmationsController.class_eval do
  protected
    # Override of devise method in Devise::ConfirmationsController
    def after_confirmation_path_for(resource_name, resource)
      spree.admin_path
    end
end