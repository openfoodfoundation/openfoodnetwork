# frozen_string_literal: true

module PermittedAttributes
  class Checkout
    def initialize(params)
      @params = params
    end

    def call
      @params.permit(
        order: [
          :email, :special_instructions,
          :existing_card_id, :shipping_method_id,
          { payments_attributes: [
            :payment_method_id,
            { source_attributes: PermittedAttributes::PaymentSource.attributes }
          ],
            ship_address_attributes: PermittedAttributes::Address.attributes,
            bill_address_attributes: PermittedAttributes::Address.attributes }
        ],
        payment_source: PermittedAttributes::PaymentSource.attributes
      )
    end
  end
end
