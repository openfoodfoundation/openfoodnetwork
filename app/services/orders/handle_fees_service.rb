# frozen_string_literal: true

module Orders
  class HandleFeesService # rubocop:disable Metrics/ClassLength
    attr_reader :order

    delegate :distributor, :order_cycle, to: :order

    FeeValue = Struct.new(:fee, :role, keyword_init: true)

    def initialize(order)
      @order = order
    end

    def recreate_all_fees!
      # `with_lock` acquires an exclusive row lock on order so no other
      # requests can update it until the transaction is commited.
      # See https://github.com/rails/rails/blob/3-2-stable/activerecord/lib/active_record/locking/pessimistic.rb#L69
      # and https://www.postgresql.org/docs/current/static/sql-select.html#SQL-FOR-UPDATE-SHARE
      order.with_lock do
        EnterpriseFee.clear_order_adjustments order

        # To prevent issue with fee being removed when a product is not linked to the order cycle
        # anymore, we now create or update line item fees.
        # Previously fees were deleted and recreated, like we still do for order fees.
        create_or_update_line_item_fees!
        create_order_fees!
      end

      tax_enterprise_fees! unless order.before_payment_state?
      order.update_order!
    end

    def create_or_update_line_item_fees!
      order.line_items.includes(:variant).each do |line_item|
        # No fee associated with the line item so we just create them
        if line_item.enterprise_fee_adjustments.blank?
          create_line_item_fees!(line_item)
          next
        end
        create_or_update_line_item_fee!(line_item)

        # delete any fees removed from the Order Cycle
        delete_removed_fees!(line_item)
      end
    end

    def create_order_fees!
      return unless order_cycle

      calculator.create_order_adjustments_for order
    end

    def tax_enterprise_fees!
      Spree::TaxRate.adjust(order, order.all_adjustments.enterprise_fee)
    end

    def update_line_item_fees!(line_item)
      line_item.adjustments.enterprise_fee.each do |fee|
        fee.update_adjustment!(line_item, force: true)
      end
    end

    def update_order_fees!
      order.adjustments.enterprise_fee.where(adjustable_type: 'Spree::Order').each do |fee|
        fee.update_adjustment!(order, force: true)
      end
    end

    private

    def create_line_item_fees!(line_item)
      return unless provided_by_order_cycle? line_item

      calculator.create_line_item_adjustments_for(line_item)
    end

    def create_or_update_line_item_fee!(line_item)
      applicators = calculator.per_item_enterprise_fee_applicators_for(line_item.variant)

      applicators.each do |fee_applicator|
        fee_adjustment = line_item.adjustments.by_originator_and_enterprise_role(
          fee_applicator.enterprise_fee, fee_applicator.role
        )

        if fee_adjustment
          fee_adjustment.update_adjustment!(line_item, force: true)
        elsif provided_by_order_cycle? line_item
          fee_applicator.create_line_item_adjustment(line_item)
        end
      end

      # Update any fees not already processed
      fees_to_update = order_cycle_fees.map(&:fee) - applicators.map(&:enterprise_fee)
      update_fee_adjustments!(line_item, fees_to_update)
    end

    def update_fee_adjustments!(line_item, fees_to_update)
      fees_to_update.each do |fee|
        fee_adjustment = line_item.adjustments.find_by(originator: fee)

        fee_adjustment&.update_adjustment!(line_item, force: true)
      end
    end

    def delete_removed_fees!(line_item)
      removed_fees = line_item.enterprise_fee_adjustments.where.not(
        originator: order_cycle_fees.map(&:fee)
      )

      # The same fee can be used in the incoming and outgoing exchange, (supplier and distributor
      # fees), so we need an extra check to see if a fee linked to both exchanges has been removed
      order_cycle_fees.each do |order_cycle_fee|
        # Check if there is any fee adjustment with a role other than the one in the order cycle fee
        fee = line_item.enterprise_fee_adjustments.by_originator_and_not_enterprise_role(
          order_cycle_fee.fee, order_cycle_fee.role
        )

        # Check if the fee matches a fee linked to the order cycle
        if fee.nil? || order_cycle_fees_include_fee?(fee)
          next
        end

        # If not linked to the order cycle we add it to the list of fee to be removed
        removed_fees = removed_fees.to_a.push(fee)
      end

      removed_fees.each(&:destroy)
    end

    def order_cycle_fees
      return @order_cycle_fees if defined? @order_cycle_fees

      @order_cycle_fees = begin
        fees = []

        return fees unless order_cycle && distributor

        order_cycle.exchanges.supplying_to(distributor).each do |exchange|
          exchange.enterprise_fees.per_item.each do |enterprise_fee|
            fee_value = FeeValue.new(fee: enterprise_fee, role: exchange.role)
            fees << fee_value
          end
        end

        order_cycle.coordinator_fees.per_item.each do |enterprise_fee|
          fees << FeeValue.new(fee: enterprise_fee, role: "coordinator")
        end

        fees
      end
    end

    def order_cycle_fees_include_fee?(fee)
      matching = order_cycle_fees.select do |order_cycle_fee|
        order_cycle_fee.fee == fee.originator &&
          order_cycle_fee.role == fee.metadata.enterprise_role
      end
      matching.present?
    end

    def calculator
      @calculator ||= OpenFoodNetwork::EnterpriseFeeCalculator.new(distributor, order_cycle)
    end

    def provided_by_order_cycle?(line_item)
      @order_cycle_variant_ids ||= order_cycle&.variants&.map(&:id) || []
      @order_cycle_variant_ids.include? line_item.variant_id
    end
  end
end
