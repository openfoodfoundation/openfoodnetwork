# frozen_string_literal: true

require "tasks/sample_data/addressing"
require "tasks/sample_data/logging"

module SampleData
  class PaymentMethodFactory
    include Logging
    include Addressing

    def create_samples(enterprises)
      log "Creating payment methods:"
      distributors = enterprises.select(&:is_distributor)
      distributors.each do |enterprise|
        create_payment_methods(enterprise)
      end
    end

    private

    def create_payment_methods(enterprise)
      return if enterprise.payment_methods.present?

      log "- #{enterprise.name}"
      create_cash_method(enterprise)
      create_card_method(enterprise)
    end

    def create_cash_method(enterprise)
      create_payment_method(
        Spree::PaymentMethod::Check,
        enterprise,
        "Cash on collection",
        "Pay on collection!",
        ::Calculator::FlatRate.new
      )
    end

    def create_card_method(enterprise)
      create_payment_method(
        Spree::Gateway::Bogus,
        enterprise,
        "Credit card (fake)",
        "We charge 1%, but won't ask for your details. ;-)",
        ::Calculator::FlatPercentItemTotal.new(preferred_flat_percent: 1)
      )
    end

    def create_payment_method(provider_class, enterprise, name, description, calculator)
      payment_method = provider_class.new(
        name: name,
        description: description,
        environment: Rails.env,
        distributor_ids: [enterprise.id]
      )
      payment_method.calculator = calculator
      payment_method.save!
    end
  end
end
