# frozen_string_literal: true

module Orders
  class CustomerCreditService
    class Response
      attr_reader :message

      def initialize(success:, message:)
        @success = success
        @message = message
      end

      def success?
        @success
      end

      def failure?
        !success?
      end
    end
  end
end
