# frozen_string_literal: true

module Orders
  class HandleFeesService
    attr_reader :order

    delegate :distributor, :order_cycle, to: :order

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

    def calculator
      @calculator ||= OpenFoodNetwork::EnterpriseFeeCalculator.new(distributor, order_cycle)
    end

    def provided_by_order_cycle?(line_item)
      @order_cycle_variant_ids ||= order_cycle&.variants&.map(&:id) || []
      @order_cycle_variant_ids.include? line_item.variant_id
    end

    def create_line_item_fees!(line_item)
      return unless provided_by_order_cycle? line_item

      calculator.create_line_item_adjustments_for(line_item)
    end

    def create_or_update_line_item_fee!(line_item)
      fee_applicators(line_item.variant).each do |fee_applicator|
        fee_adjustment = line_item.adjustments.find_by(originator: fee_applicator.enterprise_fee)

        if fee_adjustment
          fee_adjustment.update_adjustment!(line_item, force: true)
        elsif provided_by_order_cycle? line_item
          fee_applicator.create_line_item_adjustment(line_item)
        end
      end
    end

    def delete_removed_fees!(line_item)
      order_cycle_fees = fee_applicators(line_item.variant).map(&:enterprise_fee)
      removed_fees = line_item.enterprise_fee_adjustments.where.not(originator: order_cycle_fees)

      removed_fees.each(&:destroy)
    end

    def fee_applicators(variant)
      calculator.order_cycle_per_item_enterprise_fee_applicators_for(variant)
    end
  end
end
