# frozen_string_literal: true

module Forms
  class EnterpriseFeesBulkUpdate
    include ActiveModel::Model

    validate :check_enterprise_fee_input
    validate :check_calculators_compatibility_with_taxes

    def initialize(params)
      @errors = ActiveModel::Errors.new self
      @params = params
    end

    def save
      return false unless valid?

      @enterprise_fee_set = Sets::EnterpriseFeeSet.new(@params)
      @enterprise_fee_set.save
      true
    end

    def check_enterprise_fee_input
      @params['collection_attributes'].each do |_, fee_row|
        enterprise_fees = fee_row['calculator_attributes']&.slice(
          :preferred_flat_percent, :preferred_amount,
          :preferred_first_item, :preferred_additional_item,
          :preferred_minimal_amount, :preferred_normal_amount,
          :preferred_discount_amount, :preferred_per_unit
        )

        next unless enterprise_fees

        enterprise_fees.each do |_, enterprise_amount|
          unless enterprise_amount.nil? || Float(enterprise_amount, exception: false)
            @errors.add(:base, I18n.t(:calculator_preferred_value_error))
            return false
          end
        end
        return true
      end
    end

    def check_calculators_compatibility_with_taxes
      @params['collection_attributes'].each do |_, enterprise_fee|
        next unless enterprise_fee['inherits_tax_category'] == "true"
        next unless EnterpriseFee::PER_ORDER_CALCULATORS.include?(enterprise_fee['calculator_type'])

        @errors.add(
          :base,
          I18n.t(
            'activerecord.errors.models.enterprise_fee.inherit_tax_requires_per_item_calculator'
          )
        )
        return false
      end
      true
    end
  end
end
