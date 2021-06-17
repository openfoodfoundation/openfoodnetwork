# frozen_string_literal: true

require "tasks/sample_data/logging"

module SampleData
  class FeeFactory
    include Logging

    def create_samples(enterprises)
      log "Creating fees:"
      enterprises.each do |enterprise|
        next if enterprise.enterprise_fees.present?

        log "- #{enterprise.name} charges markup"
        calculator = Calculator::FlatPercentPerItem.new(preferred_flat_percent: 10)
        create_fee(enterprise, calculator)
        calculator.save!
      end
    end

    private

    def create_fee(enterprise, calculator)
      fee = enterprise.enterprise_fees.new(
        fee_type: "sales",
        name: "markup",
        inherits_tax_category: true,
      )
      fee.calculator = calculator
      fee.save!
    end
  end
end
