class Delivery

  # Constructor
  #
  # @param order [Spree::Order]
  def initialize(order)
    @order = order
  end

  # Returns the appropriate ship address when the form field is cleared
  #
  # @return [Spree::Address]
  def ship_address_on_clear
    order.ship_address
  end

  private

  attr_reader :order
end
