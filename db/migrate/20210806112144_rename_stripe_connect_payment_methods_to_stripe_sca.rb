class RenameStripeConnectPaymentMethodsToStripeSca < ActiveRecord::Migration[6.1]
  def change
    Spree::PaymentMethod
      .where(type: "Spree::Gateway::StripeConnect")
      .update_all(type: "Spree::Gateway::StripeSCA")
  end
end
