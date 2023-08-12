# frozen_string_literal: true

module Checkout
  class Validation
    def initialize(order, params)
      @params = params
      @order = order
    end

    def call
      __send__ "validate_#{current_step}"
    end

    private

    attr_reader :order, :params

    def current_step
      ([params[:step]] & ["details", "payment", "summary"]).first
    end

    def validate_details
      return true if params[:shipping_method_id].present?

      order.errors.add :shipping_method, I18n.t('split_checkout.errors.select_a_shipping_method')
    end

    def validate_payment
      return true if params.dig(:order, :payments_attributes, 0, :payment_method_id).present?
      return true if order.zero_priced_order?

      order.errors.add :payment_method, I18n.t('split_checkout.errors.select_a_payment_method')
    end

    def validate_summary
      return true if params[:accept_terms]
      return true unless TermsOfService.required?(order.distributor)

      order.errors.add(:terms_and_conditions, I18n.t("split_checkout.errors.terms_not_accepted"))
    end
  end
end
