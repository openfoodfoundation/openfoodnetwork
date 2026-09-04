# frozen_string_literal: true

class ShipOrderComponent < ViewComponent::Base
  def initialize(order:, replace_row: false)
    @order = order
    @replace_row = replace_row
  end
end
