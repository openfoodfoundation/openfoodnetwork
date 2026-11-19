# frozen_string_literal: true

require "digest"
require_relative "address"

module NanoPayment
  # Binds a Nano send to one payment (xno-binding v1, option C).
  #
  # A Nano send carries no memo, so a block hash alone proves only that an
  # amount reached an account. The buyer therefore sets the send block's
  # representative to an account derived from the payment:
  #
  #   SHA256("xno-binding/v1/rep|" + payment_ref + "|" + pay_to + "|" + raw)
  #
  # A block made for one payment cannot be presented for another one, or for
  # the same payment at a different amount.
  module Binding
    DOMAIN = "xno-binding/v1/rep|"

    module_function

    def commitment_hex(payment_ref, pay_to, raw)
      Digest::SHA256.hexdigest("#{DOMAIN}#{payment_ref}|#{pay_to}|#{Integer(raw)}")
    end

    def representative(payment_ref, pay_to, raw)
      Address.from_public_key(commitment_hex(payment_ref, pay_to, raw))
    end
  end
end
