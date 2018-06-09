Spree::Admin::Orders::CustomerDetailsController.class_eval do
  before_filter :set_guest_checkout_status, only: :update

  # Inherit CanCan permissions for the current order
  def model_class
    load_order unless @order
    @order
  end

  private

  def set_guest_checkout_status
    registered_user = Spree::User.find_by_email(params[:order][:email])

    params[:order][:guest_checkout] = registered_user.nil?

    return unless registered_user
    @order.user_id = registered_user.id
  end
end
