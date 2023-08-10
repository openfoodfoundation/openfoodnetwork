# frozen_string_literal: true

module OrderManagement
  module Order
    class Updater
      attr_reader :order

      delegate :payments, :line_items, :adjustments, :all_adjustments, :shipments, to: :order

      def initialize(order)
        @order = order
      end

      # This is a multi-purpose method for processing logic related to changes in the Order.
      # It is meant to be called from various observers so that the Order is aware of changes
      # that affect totals and other values stored in the Order.
      #
      # This method should never do anything to the Order that results in a save call on the
      # object with callbacks (otherwise you will end up in an infinite recursion as the
      # associations try to save and then in turn try to call +update!+ again.)
      def update
        update_all_adjustments
        update_totals_and_states
      end

      def update_totals_and_states
        handle_legacy_taxes

        update_totals

        if order.completed?
          update_payment_state
          update_shipments
          update_shipment_state
        end

        persist_totals
        update_pending_payment
      end

      def update_pending_payment
        return unless order.state.in? ["payment", "confirmation"]
        return unless order.pending_payments.any?

        order.pending_payments.first.update_attribute :amount, order.total
      end

      # Updates the following Order total values:
      #
      # - payment_total - total value of all finalized Payments (excludes non-finalized Payments)
      # - item_total - total value of all LineItems
      # - adjustment_total - total value of all adjustments
      # - total - order total, it's the equivalent to item_total plus adjustment_total
      def update_totals
        update_payment_total
        update_item_total
        update_adjustment_total
        update_order_total
      end

      # Give each of the shipments a chance to update themselves
      def update_shipments
        shipments.each { |shipment| shipment.update!(order) }
      end

      def update_payment_total
        order.payment_total = payments.completed.sum(:amount)
      end

      def update_item_total
        order.item_total = line_items.sum('price * quantity')
        update_order_total
      end

      def update_adjustment_total
        order.adjustment_total = all_adjustments.additional.eligible.sum(:amount)
        order.additional_tax_total = all_adjustments.tax.additional.sum(:amount)
        order.included_tax_total = all_adjustments.tax.inclusive.sum(:amount)
      end

      def update_order_total
        order.total = order.item_total + order.adjustment_total
      end

      def persist_totals
        order.update_columns(
          payment_state: order.payment_state,
          shipment_state: order.shipment_state,
          item_total: order.item_total,
          adjustment_total: order.adjustment_total,
          included_tax_total: order.included_tax_total,
          additional_tax_total: order.additional_tax_total,
          payment_total: order.payment_total,
          total: order.total,
          updated_at: Time.zone.now
        )
      end

      # Updates the +shipment_state+ attribute according to the following logic:
      #
      # - shipped - when the order shipment is in the "shipped" state
      # - ready - when the order shipment is in the "ready" state
      # - backorder - when there is backordered inventory associated with an order
      # - pending - when the shipment is in the "pending" state
      #
      # The +shipment_state+ value helps with reporting, etc. since it provides a quick and easy way
      #   to locate Orders needing attention.
      def update_shipment_state
        order.shipment_state = if order.shipment&.backordered?
                                 'backorder'
                               else
                                 # It returns nil if there is no shipment
                                 order.shipment&.state
                               end

        order.state_changed('shipment')
        order.shipment_state
      end

      # Updates the +payment_state+ attribute according to the following logic:
      #
      # - paid - when +payment_total+ is equal to +total+
      # - balance_due - when +payment_total+ is less than +total+
      # - credit_owed - when +payment_total+ is greater than +total+
      # - failed - when most recent payment is in the failed state
      #
      # The +payment_state+ value helps with reporting, etc. since it provides a quick and easy way
      #   to locate Orders needing attention.
      def update_payment_state
        last_payment_state = order.payment_state

        order.payment_state = infer_payment_state
        cancel_payments_requiring_auth unless last_payment_state == "paid"
        track_payment_state_change(last_payment_state)

        order.payment_state
      end

      def update_all_adjustments
        # Voucher are modelled as a Spree::Adjustment but  they don't behave like all the other
        # adjustments, so we don't want voucher adjustment to be updated here.
        # Calculation are handled by VoucherAdjustmentsService.calculate
        order.all_adjustments.non_voucher.reload.each(&:update_adjustment!)
      end

      # Sets the distributor's address as shipping address of the order for those
      # shipments using a shipping method that doesn't require address, such us
      # a pickup.
      def shipping_address_from_distributor
        return if order.shipping_method.blank? || order.shipping_method.require_ship_address

        order.ship_address = order.address_from_distributor
      end

      def after_payment_update(payment)
        if payment.completed? || payment.void?
          update_payment_total
        end

        if order.completed?
          update_payment_state
          update_shipments
          update_shipment_state
        end

        if payment.completed? || order.completed?
          persist_totals
        end
      end

      private

      def cancel_payments_requiring_auth
        return unless order.payment_state == "paid"

        payments.to_a.select(&:requires_authorization?).each(&:void_transaction!)
      end

      def round_money(value)
        (value * 100).round / 100.0
      end

      def infer_payment_state
        if failed_payments?
          'failed'
        elsif canceled_and_not_paid_for?
          'void'
        elsif requires_authorization?
          'requires_authorization'
        else
          infer_payment_state_from_balance
        end
      end

      def infer_payment_state_from_balance
        # This part added so that we don't need to override
        # order.outstanding_balance
        balance = order.new_outstanding_balance

        infer_state(balance)
      end

      def infer_state(balance)
        if balance.positive?
          'balance_due'
        elsif balance.negative?
          'credit_owed'
        elsif balance.zero?
          'paid'
        end
      end

      # Tracks the state transition through a state_change for this order. It
      # does so until the last state is reached. That is, when the infered next
      # state is the same as the order has now.
      #
      # @param last_payment_state [String]
      def track_payment_state_change(last_payment_state)
        return if last_payment_state == order.payment_state

        order.state_changed('payment')
      end

      def canceled_and_not_paid_for?
        order.state == 'canceled' && order.payment_total.zero?
      end

      def failed_payments?
        payments.present? && payments.valid.empty?
      end

      # Re-applies tax if any legacy taxes are present
      def handle_legacy_taxes
        return unless order.completed? && order.adjustments.legacy_tax.any?

        order.create_tax_charge!
      end

      def requires_authorization?
        payments.requires_authorization.any? && payments.completed.empty?
      end
    end
  end
end
