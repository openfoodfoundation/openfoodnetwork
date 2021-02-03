class RenameMigsPaymentMethodsToCheck < ActiveRecord::Migration
  def change
    Spree::PaymentMethod
      .where(type: "Spree::Gateway::Migs")
      .update_all(type: "Spree::PaymentMethod::Check")
  end
end
