require 'open_food_network/standing_order_summary'

# Used by for StandingOrderPlacementJob and StandingOrderConfirmJob to summarize the
# result of automatic processing of standing orders for the relevant shop owners.
module OpenFoodNetwork
  class StandingOrderSummarizer
    def initialize
      @summaries = {}
    end

    def record_order(order)
      summary_for(order).record_order(order)
    end

    def record_success(order)
      summary_for(order).record_success(order)
    end

    def record_issue(type, order, message=nil)
      summary_for(order).record_issue(type, order, message)
    end

    def record_failure(order)
      line1 = "StandingOrderPlacementError: Cannot process order #{order.number} due to errors"
      line2 = "Errors: #{order.errors.full_messages.join(', ')}"
      Rails.logger.info("#{line1}\n#{line2}")
      record_issue(:failure, order, line2)
    end

    def send_placement_summary_emails
      @summaries.values.each do |summary|
        StandingOrderMailer.placement_summary_email(summary).deliver
      end
    end

    private

    def summary_for(order)
      shop_id = order.distributor_id
      @summaries[shop_id] ||= StandingOrderSummary.new(shop_id)
    end
  end
end
