# frozen_string_literal: true

class ShipOrderComponent < ViewComponent::Base
  def initialize(order:, current_page:)
    @order = order
    @current_page = current_page
  end
end
