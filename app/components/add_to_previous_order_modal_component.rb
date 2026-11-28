# frozen_string_literal: true

# Asks customers starting a checkout whether to add their cart to an order they already placed in
# this shop and order cycle, or to create a new order. With several orders, they pick one.
class AddToPreviousOrderModalComponent < ModalComponent
  # selected: the number of the order to select first, e.g. the one the customer came from.
  def initialize(orders:, selected: nil)
    super(id: "add-to-previous-order", modal_class: :medium, instant: true, close_button: false)

    @orders = orders
    @selected = selected
  end

  private

  def order_options
    @orders.map do |order|
      label = t("add_to_previous_order_modal_component.order_option",
                number: order.number, total: order.display_total)
      [label, order.number]
    end
  end
end
