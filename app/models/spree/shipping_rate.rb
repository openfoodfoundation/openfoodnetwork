# frozen_string_literal: true

module Spree
  class ShippingRate < ApplicationRecord
    self.belongs_to_required_by_default = false

    belongs_to :shipment, class_name: 'Spree::Shipment'
    belongs_to :shipping_method, class_name: 'Spree::ShippingMethod', inverse_of: :shipping_rates

    scope :frontend,
          -> {
            includes(:shipping_method).
              merge(ShippingMethod.frontend).
              references(:shipping_method).
              order("cost ASC")
          }

    delegate :order, :currency, to: :shipment
    delegate :name, to: :shipping_method

    def display_price
      Spree::Money.new(cost, { currency: currency })
    end

    alias_method :display_cost, :display_price
  end
end
