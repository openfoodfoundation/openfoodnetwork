# frozen_string_literal: true

# Adapts checkout form data (params) so that the order can be directly saved to the database
module Checkout
  class FormDataAdapter
    attr_reader :params, :shipping_method_id

    def initialize(params, order, current_user)
      @params = params.deep_dup.to_h.with_indifferent_access
      @order = order
      @current_user = current_user

      move_payment_source_to_payment_attributes!

      fill_in_card_type

      set_amount_in_payments_attributes

      construct_saved_card_attributes if @params.dig(:order, :existing_card_id)

      @shipping_method_id = @params[:order]&.delete(:shipping_method_id)
    end

    private

    # For payment step, filter order parameters to produce the expected
    #   nested attributes for a single payment and its source,
    #   discarding attributes for payment methods other than the one selected
    def move_payment_source_to_payment_attributes!
      return unless @params[:payment_source].present? &&
                    payment_source_params = delete_payment_source_params!

      @params.dig(:order, :payments_attributes).first[:source_attributes] = payment_source_params
    end

    # Ensures cc_type is always passed to the model by inferring the type when
    # the frontend didn't provide it.
    def fill_in_card_type
      return unless payment_source_attributes

      return if payment_source_attributes.dig(:number).blank?

      payment_source_attributes[:cc_type] ||= card_brand(payment_source_attributes[:number])
    end

    def payment_source_attributes
      @payment_source_attributes ||=
        @params.dig(:order, :payments_attributes)&.first&.dig(:source_attributes)
    end

    def card_brand(number)
      ActiveMerchant::Billing::CreditCard.brand?(number)
    end

    def delete_payment_source_params!
      @params.delete(:payment_source)[
        @params.dig(:order, :payments_attributes).first[:payment_method_id].underscore
      ]
    end

    def set_amount_in_payments_attributes
      return unless @params.dig(:order, :payments_attributes)

      @params.dig(:order, :payments_attributes).first[:amount] = @order.total
    end

    def construct_saved_card_attributes
      existing_card_id = @params[:order].delete(:existing_card_id)
      return if existing_card_id.blank?

      add_to_payment_attributes(existing_card_id)

      @params.dig(:order, :payments_attributes).first.delete :source_attributes
    end

    def add_to_payment_attributes(existing_card_id)
      credit_card = Spree::CreditCard.find(existing_card_id)
      if credit_card.try(:user_id).blank? || credit_card.user_id != @current_user.try(:id)
        raise Spree::Core::GatewayError, I18n.t(:invalid_credit_card)
      end

      @params.dig(:order, :payments_attributes).first[:source] = credit_card
    end
  end
end
