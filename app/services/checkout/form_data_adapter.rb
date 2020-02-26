# frozen_string_literal: true

# Adapts checkout form data (params) so that the order can be directly saved to the database
module Checkout
  class FormDataAdapter
    attr_reader :params, :shipping_method_id

    def initialize(params, order, current_user)
      @params = params.dup
      @order = order
      @current_user = current_user

      move_payment_source_to_payment_attributes!

      set_amount_in_payments_attributes

      construct_saved_card_attributes if @params[:order][:existing_card_id]

      @shipping_method_id = @params[:order].delete(:shipping_method_id)
    end

    private

    # For payment step, filter order parameters to produce the expected
    #   nested attributes for a single payment and its source,
    #   discarding attributes for payment methods other than the one selected
    def move_payment_source_to_payment_attributes!
      return unless @params[:payment_source].present? &&
                    payment_source_params = delete_payment_source_params!

      @params[:order][:payments_attributes].first[:source_attributes] = payment_source_params
    end

    def delete_payment_source_params!
      @params.delete(:payment_source)[
        @params[:order][:payments_attributes].first[:payment_method_id].underscore
      ]
    end

    def set_amount_in_payments_attributes
      return unless @params[:order][:payments_attributes]

      @params[:order][:payments_attributes].first[:amount] = @order.total
    end

    def construct_saved_card_attributes
      existing_card_id = @params[:order].delete(:existing_card_id)
      return if existing_card_id.blank?

      add_to_payment_attributes(existing_card_id)

      @params[:order][:payments_attributes].first.delete :source_attributes
    end

    def add_to_payment_attributes(existing_card_id)
      credit_card = Spree::CreditCard.find(existing_card_id)
      if credit_card.try(:user_id).blank? || credit_card.user_id != @current_user.try(:id)
        raise Spree::Core::GatewayError, I18n.t(:invalid_credit_card)
      end

      @params[:order][:payments_attributes].first[:source] = credit_card
    end
  end
end
