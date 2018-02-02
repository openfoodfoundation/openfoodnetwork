require 'open_food_network/subscription_summary'

# Used by for SubscriptionPlacementJob and SubscriptionConfirmJob to summarize the
# result of automatic processing of subscriptions for the relevant shop owners.
module OpenFoodNetwork
  class SubscriptionSummarizer
    def initialize
      @summaries = {}
    end

    def record_order(order)
      summary_for(order).record_order(order)
    end

    def record_success(order)
      summary_for(order).record_success(order)
    end

    def record_issue(type, order, message = nil)
      summary_for(order).record_issue(type, order, message)
    end

    def record_and_log_error(type, order)
      return record_issue(type, order) unless order.errors.any?
      error = "Subscription#{type.to_s.camelize}Error"
      line1 = "#{error}: Cannot process order #{order.number} due to errors"
      line2 = "Errors: #{order.errors.full_messages.join(', ')}"
      Rails.logger.info("#{line1}\n#{line2}")
      record_issue(type, order, line2)
    end

    def send_placement_summary_emails
      @summaries.values.each do |summary|
        SubscriptionMailer.placement_summary_email(summary).deliver
      end
    end

    def send_confirmation_summary_emails
      @summaries.values.each do |summary|
        SubscriptionMailer.confirmation_summary_email(summary).deliver
      end
    end

    private

    def summary_for(order)
      shop_id = order.distributor_id
      @summaries[shop_id] ||= SubscriptionSummary.new(shop_id)
    end
  end
end
