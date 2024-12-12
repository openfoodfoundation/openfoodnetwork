# frozen_string_literal: true

module Orders
  class CustomerCancellationService
    def initialize(order)
      @order = order
    end

    def call
      return unless order.cancel

      Spree::OrderMailer.cancel_email_for_shop(order).deliver_later
      AmendBackorderJob.perform_later(order)
    end

    private

    attr_reader :order
  end
end
