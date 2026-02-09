# frozen_string_literal: false

module CreditPaymentMethod
  class LinkerService
    attr_reader :enterprise

    def self.link(enterprise:)
      new(enterprise: ).link
    end

    def initialize(enterprise:)
      @enterprise = enterprise
    end

    def link
      if api_payment_method.nil?
        create_api_payment_method
      else
        api_payment_method.distributors << enterprise
      end

      if credit_payment_method.nil?
        create_credit_payment_method
      else
        credit_payment_method.distributors << enterprise
      end
    end

    private

    def api_payment_method
      Spree::PaymentMethod.find_by(name: Rails.application.config.api_payment_method[:name])
    end

    def create_api_payment_method
      configured = Rails.application.config.api_payment_method
      Spree::PaymentMethod::Check.create!(
        name: configured[:name],
        description: configured[:description],
        display_on: "back_end",
        environment: Rails.env,
        distributor_ids: [enterprise.id]
      )
    end

    def credit_payment_method
      Spree::PaymentMethod.find_by(name: Rails.application.config.credit_payment_method[:name])
    end

    def create_credit_payment_method
      configured = Rails.application.config.credit_payment_method
      Spree::PaymentMethod::CustomerCredit.create!(
        name: configured[:name],
        description: configured[:description],
        display_on: "both",
        environment: Rails.env,
        distributor_ids: [enterprise.id]
      )
    end
  end
end
