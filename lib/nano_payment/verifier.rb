# frozen_string_literal: true

require_relative "address"
require_relative "amount"

module NanoPayment
  # Checks a node's `block_info` reply (with `json_block: true`) against what
  # one payment expects. Pure: no network and no database.
  module Verifier
    Result = Struct.new(:ok, :error, :payer, keyword_init: true) do
      alias_method :ok?, :ok
    end

    module_function

    # rubocop:disable Metrics/CyclomaticComplexity
    def verify(block_info, pay_to:, raw:, representative:, not_before:)
      info = block_info.is_a?(Hash) ? block_info : {}
      contents = info["contents"].is_a?(Hash) ? info["contents"] : {}

      error =
        if info["confirmed"].to_s != "true"
          :not_confirmed
        elsif info["subtype"] != "send" || !Address.valid?(info["block_account"])
          :not_a_send
        elsif !Address.same_account?(contents["link_as_account"], pay_to)
          :wrong_destination
        elsif !Amount.raw?(info["amount"]) || Integer(info["amount"], 10) != Integer(raw)
          :wrong_amount
        elsif !Address.same_account?(contents["representative"], representative)
          :not_bound
        elsif !timestamp_ok?(info["local_timestamp"], not_before)
          :too_old
        end

      return Result.new(ok: false, error:) if error

      Result.new(ok: true, error: nil, payer: info["block_account"])
    end
    # rubocop:enable Metrics/CyclomaticComplexity

    # A block the node first saw before the payment existed cannot be for it.
    def timestamp_ok?(timestamp, not_before)
      text = timestamp.to_s
      return false unless text.match?(/\A[1-9]\d*\z/)

      Integer(text, 10) >= not_before.to_i
    end
  end
end
