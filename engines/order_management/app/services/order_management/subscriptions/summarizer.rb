# frozen_string_literal: true

# Used by for SubscriptionPlacementJob and SubscriptionConfirmJob to summarize the
# result of automatic processing of subscriptions for the relevant shop owners.
module OrderManagement
  module Subscriptions
    class Summarizer
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
        JobLogger.logger.info("Issue in Subscription Order #{order.id}: #{type}")
        summary_for(order).record_issue(type, order, message)
      end

      def record_and_log_error(type, order, error_message = nil)
        return record_issue(type, order) unless order.errors.any?

        error = "Subscription#{type.to_s.camelize}Error"
        line1 = "#{error}: Cannot process order #{order.number} due to errors"

        error_message ||= order.errors.full_messages.join(', ')
        line2 = "Errors: #{error_message}"

        JobLogger.logger.info("#{line1}\n#{line2}")
        record_issue(type, order, line2)
      end

      def send_placement_summary_emails
        @summaries.values.each do |summary|
          SubscriptionMailer.placement_summary_email(summary).deliver_now
        end
      end

      def send_confirmation_summary_emails
        @summaries.values.each do |summary|
          SubscriptionMailer.confirmation_summary_email(summary).deliver_now
        end
      end

      private

      def summary_for(order)
        shop_id = order.distributor_id
        @summaries[shop_id] ||= Summary.new(shop_id)
      end
    end
  end
end
