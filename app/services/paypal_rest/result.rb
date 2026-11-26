# frozen_string_literal: true

module PaypalRest
  class Result
    attr_reader :order_id, :approval_url, :capture_id, :payer_id,
                :status, :refund_id, :error_message, :amount, :currency_code

    def initialize(success:, order_id: nil, approval_url: nil, capture_id: nil,
                   payer_id: nil, status: nil, refund_id: nil, error_message: nil,
                   amount: nil, currency_code: nil)
      @success = success
      @order_id = order_id
      @approval_url = approval_url
      @capture_id = capture_id
      @payer_id = payer_id
      @status = status
      @refund_id = refund_id
      @error_message = error_message
      @amount = amount
      @currency_code = currency_code
    end

    def success?
      @success
    end

    def failure?
      !success?
    end

    delegate :to_s, to: :error_message
  end
end
