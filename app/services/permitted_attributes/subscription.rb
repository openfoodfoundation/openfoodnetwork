# frozen_string_literal: true

module PermittedAttributes
  class Subscription
    def initialize(params)
      @params = params
    end

    def call
      return {} if @params[:subscription].blank?

      @params.require(:subscription).permit(basic_permitted_attributes + other_permitted_attributes)
    end

    private

    def basic_permitted_attributes
      [
        :id, :shop_id, :schedule_id, :customer_id,
        :payment_method_id, :shipping_method_id,
        :begins_at, :ends_at,
        :canceled_at, :paused_at,
        :shipping_fee_estimate, :payment_fee_estimate,
      ]
    end

    def other_permitted_attributes
      [
        subscription_line_items_attributes: [
          :id, :quantity, :variant_id, :price_estimate, :_destroy
        ],
        bill_address_attributes: PermittedAttributes::Address.attributes,
        ship_address_attributes: PermittedAttributes::Address.attributes
      ]
    end
  end
end
