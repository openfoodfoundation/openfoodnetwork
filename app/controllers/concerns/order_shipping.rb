# frozen_string_literal: true

module OrderShipping
  extend ActiveSupport::Concern

  private

  def no_ship_address_needed?
    @order.errors[:shipping_method].present? || params[:ship_address_same_as_billing] == "1"
  end

  def remove_ship_address_errors
    @order.errors.delete("ship_address.firstname")
    @order.errors.delete("ship_address.address1")
    @order.errors.delete("ship_address.city")
    @order.errors.delete("ship_address.phone")
    @order.errors.delete("ship_address.lastname")
    @order.errors.delete("ship_address.zipcode")
  end

  def bill_address_error_order(error)
    case error.attribute
    when /firstname/i then 0
    when /lastname/i then 1
    when /address1/i then 2
    when /city/i then 3
    when /zipcode/i then 4
    else 5
    end
  end

  def flash_error_when_no_shipping_method_available
    flash[:error] = I18n.t('split_checkout.errors.no_shipping_methods_available')
  end

  def use_shipping_address_from_distributor
    @order.ship_address = @order.address_from_distributor

    # Add the missing data
    bill_address = params[:order][:bill_address_attributes]
    @order.ship_address.firstname = bill_address[:firstname]
    @order.ship_address.lastname = bill_address[:lastname]
    @order.ship_address.phone = bill_address[:phone]

    # Remove shipping address from parameter so we don't override the address we just set
    params[:order].delete(:ship_address_attributes)
  end

  def shipping_method_ship_address_not_required?
    selected_shipping_method = available_shipping_methods&.select do |sm|
      sm.id.to_s == params[:shipping_method_id]
    end

    return false if selected_shipping_method.empty?

    selected_shipping_method.first.require_ship_address == false
  end
end
