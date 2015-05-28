Spree::Api::LineItemsController.class_eval do
  after_filter :apply_enterprise_fees, :only => :update

  def apply_enterprise_fees
    authorize! :read, order
    order.update_distribution_charge!
  end
end
