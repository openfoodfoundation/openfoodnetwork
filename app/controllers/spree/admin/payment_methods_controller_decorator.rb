Spree::Admin::PaymentMethodsController.class_eval do
  # Only show payment methods that user has access to and sort by distributor name
  # ! Redundant code copied from Spree::Admin::ResourceController with modifications marked
  def collection
    return parent.send(controller_name) if parent_data.present?
    collection = if model_class.respond_to?(:accessible_by) &&
                     !current_ability.has_block?(params[:action], model_class)

                   model_class.accessible_by(current_ability, action).
                     managed_by(spree_current_user).by_distributor # This line added

                 else
                   model_class.scoped.
                     managed_by(spree_current_user).by_distributor # This line added
                 end

    # This block added
    if params.key? :enterprise_id
      distributor = Enterprise.find params[:enterprise_id]
      collection = collection.for_distributor(distributor)
    end

    collection
  end
end
