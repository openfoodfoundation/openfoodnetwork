# frozen_string_literal: true

require "nano_payment"

module Spree
  class PaymentMethod
    # Nano (XNO) payments, sent by the buyer straight to the shop's account.
    #
    # There is no payment provider in between. The checkout shows the amount
    # in XNO, the shop's account and a representative account derived from
    # this payment (see NanoPayment::Binding). The buyer sends the amount with
    # that representative and enters the block hash. We read the block from
    # the Nano node configured here and complete the payment only when it is
    # a confirmed send of exactly that amount, to that account, bound to this
    # payment. The block hash is stored as the payment's response code, so it
    # can never complete a second payment.
    #
    # No key or seed is needed or stored: the shop only reads from a node.
    #
    # Preferences:
    #
    # - account: the shop's nano_ address that receives payments
    # - xno_per_unit: the price of one unit of the shop currency in XNO,
    #   e.g. "1.25" for 1 EUR = 1.25 XNO. The shop sets and updates it; a
    #   change applies to payments that are not confirmed yet.
    # - node_url: a Nano node RPC URL, e.g. https://node.example.org/rpc
    class Nano < PaymentMethod
      BLOCK_HASH = /\A\h{64}\z/
      NODE_URL = %r{\Ahttps?://\S+\z}
      # Seconds the node's clock may be behind ours.
      CLOCK_SKEW = 300

      preference :account, :string
      preference :xno_per_unit, :string
      preference :node_url, :string

      validate :validate_nano_preferences

      def actions
        %w[]
      end

      # Offered at checkout only once all three preferences are set and valid.
      def configured?
        NanoPayment::Address.valid?(preferred_account) &&
          positive_decimal?(preferred_xno_per_unit) &&
          preferred_node_url.to_s.match?(NODE_URL)
      end

      # Name of the view to display during checkout
      def method_type
        "check" # empty view
      end

      def external_gateway?
        true
      end

      # Sends the buyer to the page with the payment instructions.
      def external_payment_url(options)
        order = options.fetch(:order)
        payment = load_payment(order)

        payment.source ||= self
        payment.save! if payment.changed?

        Rails.application.routes.url_helpers.payment_gateways_nano_path(
          payment_id: payment.id, order_token: order.token
        )
      end

      def amount_raw(payment)
        NanoPayment::Amount.raw_for(payment.amount, preferred_xno_per_unit)
      end

      def amount_xno(payment)
        NanoPayment::Amount.raw_to_xno(amount_raw(payment))
      end

      # The representative the buyer sets on the send block for this payment.
      def representative(payment)
        NanoPayment::Binding.representative(payment_ref(payment), preferred_account,
                                            amount_raw(payment))
      end

      # Reads the block from the node and checks it against the payment.
      # Returns a NanoPayment::Verifier::Result.
      def check_block(payment, block_hash)
        hash = block_hash.to_s.strip.upcase
        return failed(:invalid_hash) unless BLOCK_HASH.match?(hash)
        return failed(:already_used) if used_elsewhere?(payment, hash)

        NanoPayment::Verifier.verify(
          node.block_info(hash),
          pay_to: preferred_account,
          raw: amount_raw(payment),
          representative: representative(payment),
          not_before: payment.created_at.to_i - CLOCK_SKEW,
        )
      rescue NanoPayment::Node::Error => e
        Rails.logger.error("Nano node read failed: #{e.message}")
        failed(:node_unavailable)
      end

      # Main method called by Spree::Payment::Processing when the buyer has
      # entered the block hash. The hash is in the payment's response code.
      def purchase(_money, _source, gateway_options)
        payment = gateway_options[:payment]
        result = check_block(payment, payment.response_code)

        ActiveMerchant::Billing::Response.new(
          result.ok?,
          I18n.t(result.error || :paid, scope: "payment_method_nano.status"),
          {},
          authorization: payment.response_code,
        )
      end

      private

      def load_payment(order)
        order.payments.checkout.where(payment_method: self).last
      end

      # Unique per payment: a retried payment gets a new reference, amount
      # and representative.
      def payment_ref(payment)
        "#{payment.order.number}/#{payment.identifier}"
      end

      def used_elsewhere?(payment, hash)
        nano_methods = Spree::PaymentMethod.unscoped.where(type: self.class.name).select(:id)

        Spree::Payment.where(payment_method_id: nano_methods, response_code: hash).
          where.not(id: payment.id).exists?
      end

      def failed(error)
        NanoPayment::Verifier::Result.new(ok: false, error:)
      end

      def node
        NanoPayment::Node.new(preferred_node_url)
      end

      def validate_nano_preferences
        if preferred_account.present? && !NanoPayment::Address.valid?(preferred_account)
          errors.add(:base, I18n.t("payment_method_nano.errors.account"))
        end

        if preferred_xno_per_unit.present? && !positive_decimal?(preferred_xno_per_unit)
          errors.add(:base, I18n.t("payment_method_nano.errors.xno_per_unit"))
        end

        return if preferred_node_url.blank? || preferred_node_url.match?(NODE_URL)

        errors.add(:base, I18n.t("payment_method_nano.errors.node_url"))
      end

      def positive_decimal?(value)
        NanoPayment::Amount.decimal(value).positive?
      rescue ArgumentError
        false
      end
    end
  end
end
