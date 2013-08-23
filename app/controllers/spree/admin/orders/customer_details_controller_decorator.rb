Spree::Admin::Orders::CustomerDetailsController.class_eval do
  # Inherit CanCan permissions for the current order
  def model_class
    load_order unless @order
    @order
  end
end
