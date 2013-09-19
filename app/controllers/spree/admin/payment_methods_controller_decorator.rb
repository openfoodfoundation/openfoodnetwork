Spree::Admin::PaymentMethodsController.class_eval do
  # Only show payment methods that user has access to and sort by distributor name
  # ! Redundant code copied from Spree::Admin::ResourceController with two added lines
  def collection
    return parent.send(controller_name) if parent_data.present?
    if model_class.respond_to?(:accessible_by) && !current_ability.has_block?(params[:action], model_class)
      model_class.accessible_by(current_ability, action).
        managed_by(spree_current_user).by_distributor # this line added
    else
      model_class.scoped.
        managed_by(spree_current_user).by_distributor # this line added
    end
  end
end