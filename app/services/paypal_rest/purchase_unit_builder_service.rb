# frozen_string_literal: true

module PaypalRest
  class PurchaseUnitBuilderService
    def initialize(order:, payment:, address_required: false)
      @order = order
      @payment = payment
      @address_required = address_required
    end

    def call
      items = items_builder.call
      item_total = items.sum { |item| item[:quantity].to_i * item[:unit_amount][:value].to_d }

      details = {
        invoice_id: invoice_id,
        amount: amount_details
      }

      if item_total.positive?
        details[:amount][:breakdown] = breakdown(item_total)
        details[:items] = items
      end

      details[:shipping] = shipping_details if address_required && shipping_address.present?

      details
    end

    private

    attr_reader :order, :payment, :address_required

    def items_builder
      @items_builder ||= ItemsBuilderService.new(order)
    end

    def invoice_id
      [order.number, payment&.id].compact.join("-")
    end

    def amount_details
      {
        currency_code: order.currency,
        value: format("%.2f", total_amount)
      }
    end

    def breakdown(item_total)
      details = {
        item_total: money(item_total),
        shipping: money(order.ship_total),
        tax_total: money(tax_total)
      }

      discount = items_builder.discount_total
      details[:discount] = money(discount) if discount.positive?
      details
    end

    def tax_total
      order.all_adjustments.tax.additional.sum(:amount)
    end

    def total_amount
      payment&.amount || order.total
    end

    def shipping_details
      {
        name: { full_name: shipping_address.full_name },
        address: {
          "address_line_1" => shipping_address.address1,
          "address_line_2" => shipping_address.address2,
          "admin_area_2" => shipping_address.city,
          "admin_area_1" => shipping_address.state_text,
          "postal_code" => shipping_address.zipcode,
          "country_code" => shipping_address.country&.iso
        }.compact
      }.compact
    end

    def shipping_address
      @shipping_address ||= order.ship_address
    end

    def money(value)
      {
        currency_code: order.currency,
        value: format("%.2f", value)
      }
    end
  end
end
