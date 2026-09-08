# frozen_string_literal: true

module Payments
  class WebhookPayload
    def initialize(payment:, order:, enterprise:)
      @payment = payment
      @order = order
      @enterprise = enterprise
    end

    def to_hash
      {
        payment: @payment.slice(:updated_at, :amount, :state),
        enterprise: @enterprise.slice(:abn, :acn, :name)
          .merge(address: @enterprise.address.slice(:address1, :address2, :city, :zipcode)),
        order: @order.slice(:number, :total, :currency).merge(line_items: line_items)
      }.with_indifferent_access
    end

    def self.test_data
      new(
        payment: WebhookTestData.payment,
        order: WebhookTestData.order,
        enterprise: WebhookTestData.enterprise
      )
    end

    private

    def line_items
      @order.line_items.map do |li|
        li.slice(:quantity, :price)
          .merge(
            tax_category_name: li.tax_category&.name,
            product_name: li.product.name,
            name_to_display: li.display_name,
            unit_to_display: li.unit_presentation
          )
      end
    end
  end
end
