# frozen_string_literal: true

class InvoiceDataGenerator
  attr_reader :order

  def initialize(order)
    @order = order
  end

  # Give the latest invoice's data and the currect order data
  # we want to generate a new invoice data that:
  # 1. keeps the immutable attributes
  # 2. include the update details from the order
  def generate
    return new_data if old_data.nil?

    # keep the immutable attributes
    update_order_attributes
    update_line_items
    update_payment_methods

    new_data
  end

  def serialize_for_invoice
    Invoice::OrderSerializer.new(order).serializable_hash
  end

  private

  def update_order_attributes
    [:distributor, :order_cycle, :customer].each do |attribute|
      new_data[attribute] = old_data[attribute]
    end

    return unless new_data[:shipping_method_id] == old_data[:shipping_method_id]

    new_data[:shipping_method] = old_data[:shipping_method]
  end

  # if the variant, product or supplier details are updated
  # we want to keep the old details in the invoice
  def update_line_items
    new_data[:sorted_line_items].each do |new_line_item|
      old_line_item = old_data[:sorted_line_items].find { |li| li[:id] == new_line_item[:id] }
      next if old_line_item.nil?

      new_line_item[:variant] = old_line_item[:variant]
    end
  end

  # if the payment method is updated,
  # we want to keep the old payment method in the invoice
  def update_payment_methods
    new_data[:payments].each do |new_payment|
      old_payment = old_data[:payments].find { |p| p[:id] == new_payment[:id] }
      next if old_payment.nil?

      new_payment[:payment_method] = old_payment[:payment_method]
    end
  end

  def new_data
    @new_data ||= serialize_for_invoice
  end

  def old_data
    @old_data ||= order.invoices&.last&.data
  end
end
