class RenamePinPaymentMethodsToCheck < ActiveRecord::Migration[4.2]
  def change
    Spree::PaymentMethod
      .where(type: "Spree::Gateway::Pin")
      .update_all(type: "Spree::PaymentMethod::Check")
  end
end
