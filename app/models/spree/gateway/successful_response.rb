# frozen_string_literal: true

module Spree
  class Gateway
    class SuccessfulResponse < ActiveMerchant::Billing::Response
      def initialize(message = "")
        super(true, message, {}, {})
      end
    end
  end
end
