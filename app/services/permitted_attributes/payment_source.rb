# frozen_string_literal: true

module PermittedAttributes
  class PaymentSource
    def self.attributes
      [
        :gateway_payment_profile_id, :cc_type, :last_digits,
        :month, :year, :first_name, :last_name,
        :number, :verification_value,
        :save_requested_by_customer
      ]
    end
  end
end
