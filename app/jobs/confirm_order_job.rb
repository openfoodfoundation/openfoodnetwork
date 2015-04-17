ConfirmOrderJob = Struct.new(:order_id) do
  def perform
    Spree::OrderMailer.confirm_email_for_customer(order_id).deliver
    Spree::OrderMailer.confirm_email_for_shop(order_id).deliver
  end
end
