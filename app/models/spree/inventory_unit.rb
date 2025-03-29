# frozen_string_literal: true

module Spree
  class InventoryUnit < ApplicationRecord
    self.belongs_to_required_by_default = false

    belongs_to :variant, -> { with_deleted }, class_name: "Spree::Variant",
                                              inverse_of: :inventory_units
    belongs_to :order, class_name: "Spree::Order"
    belongs_to :shipment, class_name: "Spree::Shipment"
    belongs_to :return_authorization, class_name: "Spree::ReturnAuthorization",
                                      inverse_of: :inventory_units

    scope :backordered, -> { where state: 'backordered' }
    scope :shipped, -> { where state: 'shipped' }
    scope :backordered_per_variant, ->(stock_item) do
      includes(:shipment)
        .where("spree_shipments.state != 'canceled'").references(:shipment)
        .where(variant_id: stock_item.variant_id)
        .backordered.order("#{table_name}.created_at ASC")
    end

    # state machine (see http://github.com/pluginaweek/state_machine/tree/master for details)
    state_machine initial: :on_hand do
      event :fill_backorder do
        transition to: :on_hand, from: :backordered
      end
      after_transition on: :fill_backorder, do: :update_order

      event :ship do
        transition to: :shipped, if: :allow_ship?
      end

      event :return do
        transition to: :returned, from: :shipped
      end
    end

    def self.finalize_units!(inventory_units)
      inventory_units.map do |iu|
        iu.update_columns(
          pending: false,
          updated_at: Time.zone.now
        )
      end
    end

    def find_stock_item
      Spree::StockItem.find_by(variant_id:)
    end

    private

    def allow_ship?
      Spree::Config[:allow_backorder_shipping] || on_hand?
    end

    def update_order
      order.update_order!
    end
  end
end
