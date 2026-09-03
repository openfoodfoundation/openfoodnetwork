# frozen_string_literal: true

# Create a webhook payload for an order-level event, such as an order placed
# while a payment is still due. The payload will be delivered asynchronously.

module Orders
  class WebhookPayload
    def initialize(order:, payment:, enterprise:)
      @order = order
      @payment = payment
      @enterprise = enterprise
    end

    def to_hash
      {
        order: @order.slice(:number, :email, :total, :currency)
          .merge(outstanding_balance: @order.new_outstanding_balance),
        payment_method: @payment.payment_method.slice(:id, :name),
        enterprise: @enterprise.slice(:abn, :acn, :name)
          .merge(address: @enterprise.address.slice(:address1, :address2, :city, :zipcode))
      }.with_indifferent_access
    end

    def self.test_data
      new(order: test_order, payment: test_payment, enterprise: test_enterprise)
    end

    def self.test_order
      Spree::Order.new(
        number: "R555555555",
        email: "test@example.com",
        total: 20.00,
        payment_total: 0.00,
        currency: "AUD",
      )
    end

    def self.test_payment
      Spree::Payment.new(
        amount: 20.00,
        payment_method: Spree::PaymentMethod::Check.new(id: 0, name: "Test payment method")
      )
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

    private_class_method :test_order, :test_payment, :test_enterprise
  end
end
