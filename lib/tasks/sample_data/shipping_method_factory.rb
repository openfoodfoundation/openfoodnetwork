# frozen_string_literal: true

require "tasks/sample_data/addressing"
require "tasks/sample_data/logging"

module SampleData
  class ShippingMethodFactory
    include Logging
    include Addressing

    def create_samples(enterprises)
      log "Creating shipping methods:"
      distributors = enterprises.select(&:is_distributor)
      distributors.each do |enterprise|
        create_shipping_methods(enterprise)
      end
    end

    private

    def create_shipping_methods(enterprise)
      return if enterprise.shipping_methods.present?

      log "- #{enterprise.name}"
      create_pickup(enterprise)
      create_delivery(enterprise)
    end

    def create_pickup(enterprise)
      create_shipping_method(
        enterprise,
        name: "Pickup #{enterprise.name}",
        description: "pick-up at your awesome hub gathering place",
        require_ship_address: false,
        calculator_type: "Calculator::Weight"
      )
    end

    def create_delivery(enterprise)
      delivery = create_shipping_method(
        enterprise,
        name: "Home delivery #{enterprise.name}",
        description: "yummy food delivered at your door",
        require_ship_address: true,
        calculator_type: "Calculator::FlatRate"
      )
      delivery.calculator.preferred_amount = 2
      delivery.calculator.save!
    end

    def create_shipping_method(enterprise, params)
      params[:distributor_ids] = [enterprise.id]
      method = enterprise.shipping_methods.new(params)
      method.zones << zone
      method.shipping_categories << Spree::ShippingCategory.find_or_create_by(name: 'Default')
      method.save!
      method
    end
  end
end
