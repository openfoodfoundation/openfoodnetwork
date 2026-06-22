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
        payment_method: {
          name: @payment&.payment_method&.name,
          type: @payment&.payment_method&.type
        },
        enterprise: @enterprise.slice(:abn, :acn, :name)
          .merge(address: @enterprise.address.slice(:address1, :address2, :city, :zipcode))
      }.with_indifferent_access
    end
  end
end
