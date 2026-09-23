# frozen_string_literal: true

# Create a webhook payload for an order-level event, such as an order placed
# while a balance is still due. The payload will be delivered asynchronously.

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

    # A balance is still due, so the order isn't paid for and its payment is
    # still waiting at checkout.
    def self.test_data
      new(
        order: WebhookTestData.order(total: 20.00),
        payment: WebhookTestData.payment(amount: 20.00, state: "checkout"),
        enterprise: WebhookTestData.enterprise
      )
    end
  end
end
