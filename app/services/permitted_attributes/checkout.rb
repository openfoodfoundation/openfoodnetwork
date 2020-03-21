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
          payments_attributes: [
            :payment_method_id,
            source_attributes: payment_source_attributes
          ],
          ship_address_attributes: PermittedAttributes::Address.attributes,
          bill_address_attributes: PermittedAttributes::Address.attributes
        ],
        payment_source: payment_source_attributes
      )
    end

    private

    def payment_source_attributes
      [
        :gateway_payment_profile_id, :cc_type, :last_digits,
        :month, :year, :first_name, :last_name,
        :number, :verification_value,
        :save_requested_by_customer
      ]
    end
  end
end
