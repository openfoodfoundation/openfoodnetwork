# frozen_string_literal: true

module Reporting
  module Reports
    module EnterpriseFeeSummary
      class Permissions
        attr_accessor :user

        def initialize(user)
          @user = user
        end

        def allowed_order_cycles
          @allowed_order_cycles ||= OrderCycle.visible_by(user)
        end

        def allowed_distributors
          outgoing_exchanges = Exchange.outgoing.where(order_cycle_id: allowed_order_cycle_ids)
          @allowed_distributors ||= Enterprise.where(id: outgoing_exchanges.pluck(:receiver_id))
        end

        def allowed_producers
          incoming_exchanges = Exchange.incoming.where(order_cycle_id: allowed_order_cycle_ids)
          @allowed_producers ||= Enterprise.where(id: incoming_exchanges.pluck(:sender_id))
        end

        def allowed_enterprise_fees
          return EnterpriseFee.where("1=0") if allowed_order_cycles.blank?

          coordinator_enterprise_fees = EnterpriseFee.joins(:coordinator_fees)
            .where(coordinator_fees: { order_cycle_id: allowed_order_cycle_ids })
          exchange_enterprise_fees = EnterpriseFee.joins(exchange_fees: :exchange)
            .where(exchanges: { order_cycle_id: allowed_order_cycle_ids })
          @allowed_enterprise_fees ||= (coordinator_enterprise_fees | exchange_enterprise_fees).uniq
        end

        def allowed_shipping_methods
          @allowed_shipping_methods ||= Spree::ShippingMethod.for_distributors(allowed_distributors)
        end

        def allowed_payment_methods
          @allowed_payment_methods ||= Spree::PaymentMethod.for_distributors(allowed_distributors)
        end

        private

        def allowed_order_cycle_ids
          @allowed_order_cycle_ids ||= allowed_order_cycles.map(&:id)
        end
      end
    end
  end
end
