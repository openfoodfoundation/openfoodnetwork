# frozen_string_literal: true

module Spree
  module Stock
    class AvailabilityValidator < ActiveModel::Validator
      def validate(line_item)
        # OFN specific check for in-memory :skip_stock_check attribute
        return if line_item.skip_stock_check

        quantity_to_validate = line_item.quantity - quantity_in_shipment(line_item)
        return if quantity_to_validate < 1

        validate_quantity(line_item, quantity_to_validate)
      end

      private

      # This is an adapted version of a fix to the inventory_units not being considered here.
      # See #3090 for details.
      # This can be removed after upgrading to Spree 2.4.
      def quantity_in_shipment(line_item)
        shipment = line_item_shipment(line_item)
        return 0 unless shipment

        units = shipment.inventory_units_for(line_item.variant)
        units.count
      end

      def line_item_shipment(line_item)
        return line_item.target_shipment if line_item.target_shipment
        return line_item.order.shipments.first if line_item.order&.shipments&.any?
      end

      # Overrides Spree v2.0.4 validate method version to:
      #   - scope variants to hub and thus acivate variant overrides
      #   - use calculated quantity instead of the line_item.quantity
      #   - rely on Variant.can_supply? instead of Stock::Quantified.can_supply?
      #       so that it works correctly for variant overrides
      def validate_quantity(line_item, quantity)
        line_item.scoper.scope(line_item.variant)

        add_out_of_stock_error(line_item) unless line_item.variant.can_supply? quantity
      end

      def add_out_of_stock_error(line_item)
        variant = line_item.variant
        display_name = variant.name.to_s
        display_name += %{(#{variant.options_text})} if variant.options_text.present?
        line_item.errors.add(:quantity, Spree.t(:out_of_stock,
                                                scope: :order_populator,
                                                item: display_name.inspect))
      end
    end
  end
end
