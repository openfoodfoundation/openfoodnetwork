class RenamePinPaymentMethodsToCheck < ActiveRecord::Migration
  def change
    Spree::PaymentMethod
      .where(type: "Spree::Gateway::Pin")
      .update_all(type: "Spree::PaymentMethod::Check")
  end
end
