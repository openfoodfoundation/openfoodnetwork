# frozen_string_literal: true

module OrderManagement
  module Stock
    class Package
      ContentItem = Struct.new(:variant, :quantity, :state)

      attr_reader :stock_location, :order, :contents
      attr_accessor :shipping_rates

      def initialize(stock_location, order, contents = [])
        @stock_location = stock_location
        @order = order
        @contents = contents
        @shipping_rates = []
      end

      def add(variant, quantity, state = :on_hand)
        contents << ContentItem.new(variant, quantity, state)
      end

      def weight
        contents.sum { |item| item.variant.weight * item.quantity }
      end

      def on_hand
        contents.select { |item| item.state == :on_hand }
      end

      def backordered
        contents.select { |item| item.state == :backordered }
      end

      def find_item(variant, state = :on_hand)
        contents.select do |item|
          item.variant == variant &&
            item.state == state
        end.first
      end

      def quantity(state = nil)
        case state
        when :on_hand
          on_hand.sum(&:quantity)
        when :backordered
          backordered.sum(&:quantity)
        else
          contents.sum(&:quantity)
        end
      end

      def empty?
        quantity.zero?
      end

      def flattened
        flat = []
        contents.each do |item|
          item.quantity.times do
            flat << ContentItem.new(item.variant, 1, item.state)
          end
        end
        flat
      end

      def flattened=(flattened)
        contents.clear
        flattened.each do |item|
          current_item = find_item(item.variant, item.state)
          if current_item
            current_item.quantity += 1
          else
            add(item.variant, item.quantity, item.state)
          end
        end
      end

      # Returns the shipping methods that are enabled by the order's distributor
      #
      # @return [Array<Spree::ShippingMethod>]
      def shipping_methods
        return [] unless order.distributor.present?

        order.distributor.shipping_methods.uniq.to_a
      end

      def inspect
        out = "#{order} - "
        out.dup << contents.map do |content_item|
          "#{content_item.variant.name} #{content_item.quantity} #{content_item.state}"
        end.join('/')
      end

      def to_shipment
        shipment = Spree::Shipment.new
        shipment.order = order
        shipment.stock_location = stock_location
        shipment.shipping_rates = shipping_rates

        contents.each do |item|
          item.quantity.times do
            unit = shipment.inventory_units.build
            unit.pending = true
            unit.order = order
            unit.variant = item.variant
            unit.state = item.state.to_s
          end
        end

        shipment
      end
    end
  end
end
