# frozen_string_literal: true

module Spree
  module PaymentHelper
    def payment_intent(amount, status)
      JSON.generate(
        object: "payment_intent",
        amount:,
        status:,
        charges: { data: [{ id: "ch_1234", amount: }] },
        id: "12345",
        livemode: false
      )
    end
  end
end
