# frozen_string_literal: true

require 'open_food_network/enterprise_fee_applicator'

module OpenFoodNetwork
  class EnterpriseFeeCalculator
    def initialize(distributor = nil, order_cycle = nil)
      @distributor = distributor
      @order_cycle = order_cycle
    end

    def indexed_fees_for(variant)
      load_enterprise_fees unless @indexed_enterprise_fees

      indexed_enterprise_fees_for(variant).sum do |enterprise_fee|
        calculate_fee_for variant, enterprise_fee
      end
    end

    def indexed_fees_by_type_for(variant)
      load_enterprise_fees unless @indexed_enterprise_fees

      indexed_enterprise_fees_for(variant).each_with_object({}) do |enterprise_fee, fees|
        fees[enterprise_fee.fee_type.to_sym] ||= 0
        fees[enterprise_fee.fee_type.to_sym] += calculate_fee_for variant, enterprise_fee
      end.select { |_fee_type, amount| amount > 0 }
    end

    def fees_for(variant)
      per_item_enterprise_fee_applicators_for(variant).sum do |applicator|
        calculate_fee_for variant, applicator.enterprise_fee
      end
    end

    def fees_by_type_for(variant)
      per_item_enterprise_fee_applicators_for(variant).each_with_object({}) do |applicator, fees|
        fees[applicator.enterprise_fee.fee_type.to_sym] ||= 0
        fees[applicator.enterprise_fee.fee_type.to_sym] +=
          calculate_fee_for variant, applicator.enterprise_fee
      end.select { |_fee_type, amount| amount > 0 }
    end

    def fees_name_by_type_for(variant)
      per_item_enterprise_fee_applicators_for(variant).each_with_object({}) do |applicator, fees|
        fees[applicator.enterprise_fee.fee_type.to_sym] = applicator.enterprise_fee.name
      end
    end

    def create_line_item_adjustments_for(line_item)
      variant = line_item.variant

      per_item_enterprise_fee_applicators_for(variant).each do |applicator|
        applicator.create_line_item_adjustment(line_item)
      end
    end

    def create_order_adjustments_for(order)
      per_order_enterprise_fee_applicators_for(order).each do |applicator|
        applicator.create_order_adjustment(order)
      end
    end

    def per_item_enterprise_fee_applicators_for(variant)
      fees = []

      return [] unless @order_cycle && @distributor

      @order_cycle.exchanges_carrying(variant, @distributor).each do |exchange|
        exchange.enterprise_fees.per_item.each do |enterprise_fee|
          fees << OpenFoodNetwork::EnterpriseFeeApplicator.new(enterprise_fee, variant,
                                                               exchange.role)
        end
      end

      @order_cycle.coordinator_fees.per_item.each do |enterprise_fee|
        fees << OpenFoodNetwork::EnterpriseFeeApplicator.new(enterprise_fee, variant, 'coordinator')
      end

      fees
    end

    def per_order_enterprise_fee_applicators_for(order)
      fees = []

      return fees unless @order_cycle && order.distributor

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

    private

    def load_enterprise_fees
      @indexed_enterprise_fees = {}

      exchange_fees = per_item_enterprise_fees_with_exchange_details
      load_exchange_fees exchange_fees
      load_coordinator_fees
    end

    def per_item_enterprise_fees_with_exchange_details
      EnterpriseFee.
        per_item.
        joins(exchanges: :exchange_variants).
        where('exchanges.order_cycle_id = ?', @order_cycle.id).
        merge(Exchange.supplying_to(@distributor)).
        select('enterprise_fees.*, exchange_variants.variant_id AS variant_id')
    end

    def load_exchange_fees(exchange_fees)
      exchange_fees.each do |enterprise_fee|
        @indexed_enterprise_fees[enterprise_fee.variant_id.to_i] ||= []
        @indexed_enterprise_fees[enterprise_fee.variant_id.to_i] << enterprise_fee
      end
    end

    def load_coordinator_fees
      @order_cycle.coordinator_fees.per_item.each do |enterprise_fee|
        @order_cycle.variants.map(&:id).each do |variant_id|
          @indexed_enterprise_fees[variant_id] ||= []
          @indexed_enterprise_fees[variant_id] << enterprise_fee
        end
      end
    end

    def indexed_enterprise_fees_for(variant)
      @indexed_enterprise_fees[variant.id] || []
    end

    def calculate_fee_for(variant, enterprise_fee)
      # Spree's Calculator interface accepts Orders or LineItems,
      # so we meet that interface with a struct.
      line_item = OpenStruct.new variant: variant, quantity: 1, price: variant.price,
                                 amount: variant.price
      enterprise_fee.compute_amount(line_item)
    end
  end
end
