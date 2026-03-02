# frozen_string_literal: true

module Checkout
  class Params
    def initialize(order, params, current_user)
      @params = params
      @order = order
      @current_user = current_user
    end

    def call
      return {} unless params[:order]

      apply_strong_parameters
      set_pickup_address
      set_address_details
      set_existing_card

      @order_params
    end

    private

    attr_reader :params, :order, :current_user

    def apply_strong_parameters
      @order_params = params.require(:order).permit(
        :email, :shipping_method_id, :special_instructions,
        :save_bill_address, :save_ship_address,
        bill_address_attributes: ::PermittedAttributes::Address.attributes,
        ship_address_attributes: ::PermittedAttributes::Address.attributes,
        payments_attributes: [
          :payment_method_id,
          { source_attributes: PermittedAttributes::PaymentSource.attributes }
        ]
      )
    end

    def set_pickup_address
      return unless shipping_method && !shipping_method.require_ship_address?

      order.ship_address = order.distributor.address.clone
      order.ship_address.firstname = @order_params[:bill_address_attributes][:firstname]
      order.ship_address.lastname = @order_params[:bill_address_attributes][:lastname]
      order.ship_address.phone = @order_params[:bill_address_attributes][:phone]

      @order_params.delete(:ship_address_attributes)
    end

    def set_address_details
      return unless addresses_present?

      if params[:ship_address_same_as_billing]
        set_ship_address_from_bill_address
      else
        set_basic_details
      end
    end

    def set_existing_card
      return unless existing_card_selected?

      card = Spree::CreditCard.find(params[:existing_card_id])

      if card.user_id.blank? || card.user_id != current_user&.id
        raise Spree::Core::GatewayError, I18n.t(:invalid_credit_card)
      end

      @order_params[:payments_attributes].first[:source] = card
    end

    def shipping_method
      return unless params[:shipping_method_id]

      @shipping_method ||= Spree::ShippingMethod.find(params[:shipping_method_id])
    end

    def existing_card_selected?
      @order_params[:payments_attributes] && params[:existing_card_id].present?
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
