Spree::Admin::Orders::CustomerDetailsController.class_eval do
  before_filter :check_authorization
  before_filter :set_guest_checkout_status, only: :update

  def update
    if @order.update_attributes(params[:order])
      if params[:guest_checkout] == "false"
        @order.associate_user!(Spree.user_class.find_by_email(@order.email))
      end

      AdvanceOrderService.new(@order).call

      @order.shipments.map &:refresh_rates
      flash[:success] = Spree.t('customer_details_updated')
      redirect_to admin_order_customer_path(@order)
    else
      render action: :edit
    end
  end

  # Inherit CanCan permissions for the current order
  def model_class
    load_order unless @order
    @order
  end

  private

  def check_authorization
    load_order
    session[:access_token] ||= params[:token]

    resource = @order
    action = params[:action].to_sym
    action = :edit if action == :show # show route renders :edit for this controller

    authorize! action, resource, session[:access_token]
  end

  def set_guest_checkout_status
    registered_user = Spree::User.find_by_email(params[:order][:email])

    params[:order][:guest_checkout] = registered_user.nil?

    return unless registered_user

    @order.user_id = registered_user.id
  end
end
