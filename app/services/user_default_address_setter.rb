# frozen_string_literal: true

# Sets the order addresses as the user default addresses
class UserDefaultAddressSetter
  def initialize(order, current_user)
    @order = order
    @current_user = current_user
  end

  # Sets the order bill address as the user default bill address
  def set_default_bill_address
    new_bill_address = @order.bill_address.dup.attributes.except!('created_at', 'updated_at')

    set_bill_address_attributes(@current_user, new_bill_address)
    set_bill_address_attributes(@order.customer, new_bill_address)
  end

  # Sets the order ship address as the user default ship address
  def set_default_ship_address
    new_ship_address = @order.ship_address.dup.attributes.except!('created_at', 'updated_at')

    set_ship_address_attributes(@current_user, new_ship_address)
    set_ship_address_attributes(@order.customer, new_ship_address)
  end

  private

  def set_bill_address_attributes(object, new_address)
    object.update(
      bill_address_attributes: new_address.merge('id' => object.bill_address&.id)
    )
  end

  def set_ship_address_attributes(object, new_address)
    object.update(
      ship_address_attributes: new_address.merge('id' => object.ship_address&.id)
    )
  end
end
