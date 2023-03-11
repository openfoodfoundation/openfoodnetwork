# frozen_string_literal: true

module Reporting
  module Reports
    module EnterpriseFeeSummary
      class Summarizer
        attr_reader :data

        delegate :fee_type, :enterprise_name, :fee_name, :fee_placement,
                 :fee_calculated_on_transfer_through_name, :tax_category_name, to: :representation

        def initialize(data)
          @data = data
        end

        def customer_name
          data["customer_name"]
        end

        def total_amount
          data["total_amount"]
        end

        private

        def representation
          @representation ||= representation_klass.new(data)
        end

        def representation_klass
          return DataRepresentations::PaymentMethodFee if for_payment_method?
          return DataRepresentations::ShippingMethodFee if for_shipping_method?

          enterprise_fee_adjustment_presentation_klass
        end

        def enterprise_fee_adjustment_presentation_klass
          return DataRepresentations::CoordinatorFee if for_coordinator_fee?
          return DataRepresentations::ExchangeOrderFee if for_order_adjustment_source?
          return unless for_line_item_adjustment_source?
          return DataRepresentations::IncomingExchangeLineItemFee if for_incoming_exchange?
          return DataRepresentations::OutgoingExchangeLineItemFee if for_outgoing_exchange?
        end

        def for_payment_method?
          data["payment_method_name"].present?
        end

        def for_shipping_method?
          data["shipping_method_name"].present?
        end

        def for_coordinator_fee?
          data["placement_enterprise_role"] == "coordinator"
        end

        def for_incoming_exchange?
          data["placement_enterprise_role"] == "supplier"
        end

        def for_outgoing_exchange?
          data["placement_enterprise_role"] == "distributor"
        end

        def for_order_adjustment_source?
          data["adjustment_adjustable_type"] == "Spree::Order"
        end

        def for_line_item_adjustment_source?
          data["adjustment_adjustable_type"] == "Spree::LineItem"
        end
      end
    end
  end
end
