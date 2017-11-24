module OpenFoodNetwork
  class StandingOrderSummary
    attr_reader :shop_id, :order_count, :success_count, :issues

    def initialize(shop_id)
      @shop_id = shop_id
      @order_ids = []
      @success_ids = []
      @issues = {}
    end

    def record_order(order)
      @order_ids << order.id
    end

    def record_success(order)
      @success_ids << order.id
    end

    def record_issue(type, order, message)
      issues[type] ||= []
      issues[type][order.id] = message
    end

    def order_count
      @order_ids.count
    end

    def success_count
      @success_ids.count
    end

    def issue_count
      (@order_ids - @success_ids).count
    end

    def orders_affected_by(type)
      case type
        when :other then Spree::Order.where(id: unrecorded_ids)
        else Spree::Order.where(id: issues[type].keys)
      end
    end

    def unrecorded_ids
      recorded_ids = issues.values.map(&:keys).flatten
      @order_ids - @success_ids - recorded_ids
    end
  end
end
