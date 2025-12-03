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
        order: @order.slice(:total, :currency).merge(line_items: line_items)
      }.with_indifferent_access
    end

    def self.test_data
      new(payment: test_payment, order: test_order, enterprise: test_enterprise)
    end

    def self.test_payment
      {
        updated_at: Time.zone.now,
        amount: 0.00,
        state: "completed"
      }
    end

    def self.test_order
      order = Spree::Order.new(
        total: 0.00,
        currency: "AUD",
      )

      tax_category = Spree::TaxCategory.new(name: "VAT")
      product = Spree::Product.new(name: "Test product")
      Spree::Variant.new(product:, display_name: "")
      order.line_items << Spree::LineItem.new(
        quantity: 1,
        price: 20.00,
        tax_category:,
        product:,
        unit_presentation: "1kg"
      )

      order
    end

    def self.test_enterprise
      enterprise = Enterprise.new(
        abn: "65797115831",
        acn: "",
        name: "TEST Enterprise",
      )
      enterprise.address = Spree::Address.new(
        address1: "1 testing street",
        address2: "",
        city: "TestCity",
        zipcode: "1234"
      )

      enterprise
    end

    private_class_method :test_payment, :test_order, :test_enterprise

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
