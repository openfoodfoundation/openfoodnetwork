# frozen_string_literal: true

# Asks customers starting a checkout whether to add their cart to an order they already placed in
# this shop and order cycle, or to create a new order. With several orders, they pick one.
class AddToPreviousOrderModalComponent < ModalComponent
  def initialize(orders:)
    super(id: "add-to-previous-order", modal_class: :medium, instant: true, close_button: false)

    @orders = orders
  end

  private

  def order_options
    @orders.map do |order|
      [t(".order_option", number: order.number, total: order.display_total), order.number]
    end
  end
end
