# frozen_string_literal: true

class ShipOrderComponent < ViewComponent::Base
  def initialize(order:)
    @order = order
  end
end
