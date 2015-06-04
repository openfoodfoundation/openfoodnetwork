require 'open_food_network/enterprise_fee_applicator'

module OpenFoodNetwork
  class EnterpriseFeeCalculator
    def initialize(distributor=nil, order_cycle=nil)
      @distributor = distributor
      @order_cycle = order_cycle
    end

    def indexed_fees_for(variant)
      load_applicators unless @indexed_applicators

      indexed_applicators_for(variant).sum do |applicator|
        calculate_fee_for variant, applicator
      end
    end

    def indexed_fees_by_type_for(variant)
      load_applicators unless @indexed_applicators

      indexed_applicators_for(variant).inject({}) do |fees, applicator|
        fees[applicator.enterprise_fee.fee_type.to_sym] ||= 0
        fees[applicator.enterprise_fee.fee_type.to_sym] += calculate_fee_for variant, applicator
        fees
      end.select { |fee_type, amount| amount > 0 }
    end


    def fees_for(variant)
      per_item_enterprise_fee_applicators_for(variant).sum do |applicator|
        calculate_fee_for variant, applicator
      end
    end

    def fees_by_type_for(variant)
      per_item_enterprise_fee_applicators_for(variant).inject({}) do |fees, applicator|
        fees[applicator.enterprise_fee.fee_type.to_sym] ||= 0
        fees[applicator.enterprise_fee.fee_type.to_sym] += calculate_fee_for variant, applicator
        fees
      end.select { |fee_type, amount| amount > 0 }
    end


    def create_line_item_adjustments_for(line_item)
      variant = line_item.variant
      @distributor = line_item.order.distributor
      @order_cycle = line_item.order.order_cycle

      per_item_enterprise_fee_applicators_for(variant).each do |applicator|
        applicator.create_line_item_adjustment(line_item)
      end
    end

    def create_order_adjustments_for(order)
      @distributor = order.distributor
      @order_cycle = order.order_cycle

      per_order_enterprise_fee_applicators_for(order).each do |applicator|
        applicator.create_order_adjustment(order)
      end
    end


    private

    def load_applicators
      @indexed_applicators = {}

      enterprise_fees = enterprise_fees_with_exchange_details
      indexed_variants = Spree::Variant.where(id: enterprise_fees.pluck(:variant_id)).indexed

      load_exchange_fee_applicators    enterprise_fees, indexed_variants
      load_coordinator_fee_applicators enterprise_fees, indexed_variants
    end

    def enterprise_fees_with_exchange_details
      EnterpriseFee.
        joins(:exchanges => :exchange_variants).
        where('exchanges.order_cycle_id = ?', @order_cycle.id).
        select('enterprise_fees.*, exchange_variants.variant_id AS variant_id, exchanges.incoming AS exchange_incoming')
    end

    def load_exchange_fee_applicators(enterprise_fees, indexed_variants)
      enterprise_fees.each do |enterprise_fee|
        role = enterprise_fee.exchange_incoming ? 'supplier' : 'distributor'

        @indexed_applicators[enterprise_fee.variant_id] ||= []
        @indexed_applicators[enterprise_fee.variant_id] <<
          OpenFoodNetwork::EnterpriseFeeApplicator.new(enterprise_fee, indexed_variants[enterprise_fee.variant_id], role)
      end
    end

    def load_coordinator_fee_applicators(enterprise_fees, indexed_variants)
      @order_cycle.coordinator_fees.each do |enterprise_fee|
        indexed_variants.keys.each do |variant_id|
          @indexed_applicators[variant_id] ||= []
          @indexed_applicators[variant_id] <<
            OpenFoodNetwork::EnterpriseFeeApplicator.new(enterprise_fee, indexed_variants[variant_id], 'coordinator')
        end
      end
    end

    def indexed_applicators_for(variant)
      @indexed_applicators[variant.id] || []
    end


    def calculate_fee_for(variant, applicator)
      # Spree's Calculator interface accepts Orders or LineItems,
      # so we meet that interface with a struct.
      # Amount is faked, this is a method on LineItem
      line_item = OpenStruct.new variant: variant, quantity: 1, amount: variant.price
      applicator.enterprise_fee.compute_amount(line_item)
    end

    def per_item_enterprise_fee_applicators_for(variant)
      fees = []

      @order_cycle.exchanges_carrying(variant, @distributor).each do |exchange|
        exchange.enterprise_fees.per_item.each do |enterprise_fee|
          fees << OpenFoodNetwork::EnterpriseFeeApplicator.new(enterprise_fee, variant, exchange.role)
        end
      end

      @order_cycle.coordinator_fees.per_item.each do |enterprise_fee|
        fees << OpenFoodNetwork::EnterpriseFeeApplicator.new(enterprise_fee, variant, 'coordinator')
      end

      fees
    end

    def per_order_enterprise_fee_applicators_for(order)
      fees = []

      @order_cycle.exchanges_supplying(order).each do |exchange|
        exchange.enterprise_fees.per_order.each do |enterprise_fee|
          fees << OpenFoodNetwork::EnterpriseFeeApplicator.new(enterprise_fee, nil, exchange.role)
        end
      end

      @order_cycle.coordinator_fees.per_order.each do |enterprise_fee|
        fees << OpenFoodNetwork::EnterpriseFeeApplicator.new(enterprise_fee, nil, 'coordinator')
      end

      fees
    end
  end
end
