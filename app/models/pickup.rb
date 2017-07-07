class Pickup

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
    Spree::Address.default
  end

  private

  attr_reader :order
end
