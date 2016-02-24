Spree::Api::LineItemsController.class_eval do
  around_filter :apply_enterprise_fees_with_lock, only: :update

  private

  def apply_enterprise_fees_with_lock
    authorize! :read, order
    order.with_lock do
      yield
      order.update_distribution_charge!
    end
  end
end
