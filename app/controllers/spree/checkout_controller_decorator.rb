require 'open_food_network/last_used_address'

Spree::CheckoutController.class_eval do

  include CheckoutHelper

  before_filter :enable_embedded_shopfront

  def edit
    flash.keep
    redirect_to main_app.checkout_path
  end

  private

  def before_payment
    current_order.payments.destroy_all if request.put?
  end

  # Adapted from spree_last_address gem: https://github.com/TylerRick/spree_last_address
  # Originally, we used a forked version of this gem, but encountered strange errors where
  # it worked in dev but only intermittently in staging/prod.
  def before_address
    associate_user

    lua = OpenFoodNetwork::LastUsedAddress.new(@order.email)
    last_used_bill_address = lua.last_used_bill_address.andand.clone
    last_used_ship_address = lua.last_used_ship_address.andand.clone

    preferred_bill_address, preferred_ship_address = spree_current_user.bill_address, spree_current_user.ship_address if spree_current_user.respond_to?(:bill_address) && spree_current_user.respond_to?(:ship_address)

    @order.bill_address ||= preferred_bill_address || last_used_bill_address || Spree::Address.default
    @order.ship_address ||= preferred_ship_address || last_used_ship_address || nil
  end
end
