# frozen_string_literal: true

module Checkout
  class Params
    def initialize(order, params)
      @params = params
      @order = order
    end

    def call
      return {} unless params[:order]

      apply_strong_parameters
      set_address_details
      set_payment_amount

      @order_params
    end

    private

    attr_reader :params, :order

    def apply_strong_parameters
      @order_params = params.require(:order).permit(
        :email, :shipping_method_id, :special_instructions,
        bill_address_attributes: ::PermittedAttributes::Address.attributes,
        ship_address_attributes: ::PermittedAttributes::Address.attributes,
        payments_attributes: [:payment_method_id]
      )
    end

    def set_address_details
      return unless addresses_present?

      if params[:ship_address_same_as_billing]
        set_ship_address_from_bill_address
      else
        set_basic_details
      end
    end

    def set_payment_amount
      return unless @order_params[:payments_attributes]

      @order_params[:payments_attributes].first[:amount] = order.total
    end

    def addresses_present?
      @order_params[:ship_address_attributes] && @order_params[:bill_address_attributes]
    end

    def set_ship_address_from_bill_address
      @order_params[:ship_address_attributes] = @order_params[:bill_address_attributes]
    end

    def set_basic_details
      [:firstname, :lastname, :phone].each do |attr|
        @order_params[:ship_address_attributes][attr] =
          @order_params[:bill_address_attributes][attr]
      end
    end
  end
end
