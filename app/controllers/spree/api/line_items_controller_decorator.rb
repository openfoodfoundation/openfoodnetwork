Spree::Api::LineItemsController.class_eval do
  after_filter :apply_enterprise_fees, only: :update
  around_filter :lock, only: :update

  private

  def lock
    authorize! :read, order
    @line_item = order.line_items.find(params[:id])
    @line_item.with_lock do
      yield
    end
  end

  def apply_enterprise_fees
    authorize! :read, order
    order.update_distribution_charge!
  end
end
