# frozen_string_literal: true

module PermittedAttributes
  class OrderCycle
    def initialize(params)
      @params = params
    end

    def call
      return {} if @params[:order_cycle].blank?

      @params.require(:order_cycle).permit(attributes)
    end

    def self.basic_attributes
      [
        :name, :orders_open_at, :orders_close_at, :coordinator_id,
        :preferred_product_selection_from_coordinator_inventory_only,
        :automatic_notifications,
        { schedule_ids: [], selected_distributor_payment_method_ids: [],
          selected_distributor_shipping_method_ids: [], coordinator_fee_ids: [] }
      ]
    end

    private

    def attributes
      self.class.basic_attributes + [incoming_exchanges: permitted_exchange_attributes,
                                     outgoing_exchanges: permitted_exchange_attributes]
    end

    def permitted_exchange_attributes
      [
        :id, :sender_id, :receiver_id, :enterprise_id, :incoming, :active,
        :select_all_variants, :receival_instructions,
        :pickup_time, :pickup_instructions,
        :tag_list,
        { tags: [:text],
          enterprise_fee_ids: [],
          variants: {} }
      ]
    end
  end
end
