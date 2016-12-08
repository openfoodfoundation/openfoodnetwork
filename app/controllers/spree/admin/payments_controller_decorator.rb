Spree::Admin::PaymentsController.class_eval do
  append_before_filter :filter_payment_methods


  # When a user fires an event, take them back to where they came from
  # (we can't use respond_override because Spree no longer uses respond_with)
  def fire
    return unless event = params[:e] and @payment.payment_source

    # Because we have a transition method also called void, we do this to avoid conflicts.
    event = "void_transaction" if event == "void"
    if @payment.send("#{event}!")
      flash[:success] = t(:payment_updated)
    else
      flash[:error] = t(:cannot_perform_operation)
    end
  rescue Spree::Core::GatewayError => ge
    flash[:error] = "#{ge.message}"
  ensure
    redirect_to request.referer
  end


  private

  # Only show payments for the order's distributor
  def filter_payment_methods
    @payment_methods = @payment_methods.select{ |pm| pm.has_distributor? @order.distributor}
    @payment_method ||= @payment_methods.first
  end
end
