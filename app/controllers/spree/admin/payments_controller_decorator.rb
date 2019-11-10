Spree::Admin::PaymentsController.class_eval do
  append_before_filter :filter_payment_methods

  def create
    @payment = @order.payments.build(object_params)
    if @payment.payment_method.is_a?(Spree::Gateway) && @payment.payment_method.payment_profiles_supported? && params[:card].present? && (params[:card] != 'new')
      @payment.source = CreditCard.find_by_id(params[:card])
    end

    begin
      unless @payment.save
        redirect_to admin_order_payments_path(@order)
        return
      end

      if @order.completed?
        @payment.process!
        flash[:success] = flash_message_for(@payment, :successfully_created)

        redirect_to admin_order_payments_path(@order)
      else
        AdvanceOrderService.new(@order).call!

        flash[:success] = Spree.t(:new_order_completed)
        redirect_to edit_admin_order_url(@order)
      end
    rescue Spree::Core::GatewayError => e
      flash[:error] = e.message.to_s
      redirect_to new_admin_order_payment_path(@order)
    end
  end

  # When a user fires an event, take them back to where they came from
  # (we can't use respond_override because Spree no longer uses respond_with)
  def fire
    event = params[:e]
    return unless event && @payment.payment_source

    # Because we have a transition method also called void, we do this to avoid conflicts.
    event = "void_transaction" if event == "void"
    if @payment.public_send("#{event}!")
      flash[:success] = t(:payment_updated)
    else
      flash[:error] = t(:cannot_perform_operation)
    end
  rescue Spree::Core::GatewayError => e
    flash[:error] = e.message
  ensure
    redirect_to request.referer
  end

  private

  # Only show payments for the order's distributor
  def filter_payment_methods
    @payment_methods = @payment_methods.select{ |pm| pm.has_distributor? @order.distributor }
    @payment_method ||= @payment_methods.first
  end
end
