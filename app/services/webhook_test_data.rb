# frozen_string_literal: true

# Example records describing the shape of a webhook payload, used by the
# "Test webhook endpoint" button so integrators can see what they will receive.
#
# None of these records are meant to reach the database, so they are all marked
# readonly. `readonly!` returns true rather than the record, so it is applied
# with tap.

class WebhookTestData
  def self.order(attributes = {})
    order = Spree::Order.new(
      {
        number: "R555555555",
        email: "test@example.com",
        total: 0.00,
        payment_total: 0.00,
        currency: "AUD",
      }.merge(attributes)
    )
    order.line_items << line_item

    order.tap(&:readonly!)
  end

  def self.payment(attributes = {})
    Spree::Payment.new(
      {
        updated_at: Time.zone.now,
        amount: 0.00,
        state: "completed",
        payment_method: payment_method,
      }.merge(attributes)
    ).tap(&:readonly!)
  end

  def self.enterprise
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
    ).tap(&:readonly!)

    enterprise.tap(&:readonly!)
  end

  def self.payment_method
    Spree::PaymentMethod::Check.new(id: 0, name: "Test payment method").tap(&:readonly!)
  end

  def self.line_item
    tax_category = Spree::TaxCategory.new(name: "VAT").tap(&:readonly!)
    product = Spree::Product.new(name: "Test product")
    Spree::Variant.new(product:, display_name: "")

    Spree::LineItem.new(
      quantity: 1,
      price: 20.00,
      tax_category:,
      product: product.tap(&:readonly!),
      unit_presentation: "1kg"
    ).tap(&:readonly!)
  end

  private_class_method :payment_method, :line_item
end
