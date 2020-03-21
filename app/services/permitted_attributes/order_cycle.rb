module PermittedAttributes
  class OrderCycle
    def initialize(params)
      @params = params
    end

    def call
      return @params[:order_cycle] if @params[:order_cycle].empty?

      @params.require(:order_cycle).permit(
        :name, :orders_open_at, :orders_close_at, :coordinator_id,
        :incoming_exchanges => permitted_exchange_attributes,
        :outgoing_exchanges => permitted_exchange_attributes,
        :schedule_ids => [], :coordinator_fee_ids => []
      )
    end

    private

    def permitted_exchange_attributes
      [
        :id, :sender_id, :receiver_id, :enterprise_id, :incoming, :active,
        :select_all_variants, :receival_instructions,
        :pickup_time, :pickup_instructions,
        :tag_list, :tags => [:text],
        :enterprise_fee_ids => [],
        :variants => permitted_variant_ids
      ]
    end

    # In rails 5 we will be able to permit random hash keys simply with :variants => {}
    # See https://github.com/rails/rails/commit/e86524c0c5a26ceec92895c830d1355ae47a7034
    #
    # Until then, we need to create an array of variant IDs in order to permit them
    def permitted_variant_ids
      variant_ids(@params[:order_cycle][:incoming_exchanges]) +
        variant_ids(@params[:order_cycle][:outgoing_exchanges])
    end

    def variant_ids(exchange_params)
      return [] unless exchange_params

      exchange_params.map { |exchange| exchange[:variants].map { |key, _value| key } }.flatten
    end
  end
end
