# frozen_string_literal: true

module Reporting
  module Reports
    module EnterpriseFeeSummary
      class Scope
        def initialize
          setup_default_scope
        end

        def apply_filters(params)
          filter_by_date(params)
          filter_by_distribution(params)
          filter_by_fee(params)

          self
        end

        def result
          group_data.exclude_groups_with_zero_total.select_attributes
          @scope.all
        end

        protected

        def setup_default_scope
          find_supported_adjustments

          include_adjustment_metadata
          include_order_details
          include_payment_fee_details
          include_shipping_fee_details
          include_enterprise_fee_details
          include_order_source_details
          include_line_item_source_details
          include_incoming_exchange_details
          include_outgoing_exchange_details

          group_data
          select_attributes
        end

        def find_supported_adjustments
          find_adjustments.for_orders.for_supported_adjustments
        end

        def find_adjustments
          chain_to_scope do
            Spree::Adjustment.eligible
          end
        end

        def for_orders
          chain_to_scope do
            where(
              adjustable_type: ["Spree::Order", "Spree::Shipment", "Spree::LineItem",
                                "Spree::Payment"]
            )
          end
        end

        def for_supported_adjustments
          chain_to_scope do
            where(originator_type: ["EnterpriseFee", "Spree::PaymentMethod",
                                    "Spree::ShippingMethod"])
          end
        end

        def include_adjustment_metadata
          join_scope(
            <<-JOIN_STRING.strip_heredoc
              LEFT OUTER JOIN adjustment_metadata
                ON (adjustment_metadata.adjustment_id = spree_adjustments.id)
            JOIN_STRING
          )
        end

        # Includes:
        # * Order
        # * Customer
        # * Hub
        def include_order_details
          join_scope(
            <<-JOIN_STRING.strip_heredoc
              LEFT OUTER JOIN spree_orders
                ON (
                  spree_orders.id = spree_adjustments.order_id
                    AND spree_orders.completed_at IS NOT NULL
                )
            JOIN_STRING
          )

          join_scope("LEFT OUTER JOIN customers ON (customers.id = spree_orders.customer_id)")

          join_scope(
            <<-JOIN_STRING.strip_heredoc
              LEFT OUTER JOIN enterprises AS hubs
                ON (hubs.id = spree_orders.distributor_id)
            JOIN_STRING
          )
        end

        # If for payment fee
        #
        # Includes:
        # * Payment method
        def include_payment_fee_details
          join_scope(
            <<-JOIN_STRING.strip_heredoc
              LEFT OUTER JOIN spree_payment_methods
                ON (
                  spree_adjustments.originator_type = 'Spree::PaymentMethod'
                    AND spree_payment_methods.id = spree_adjustments.originator_id
                )
            JOIN_STRING
          )

          join_scope(
            <<-JOIN_STRING.strip_heredoc
              LEFT OUTER JOIN enterprises AS payment_hubs
                ON (
                  spree_payment_methods.id IS NOT NULL
                    AND payment_hubs.id = spree_orders.distributor_id
                )
            JOIN_STRING
          )
        end

        # If for shipping fee
        #
        # Includes:
        # * Shipping method
        def include_shipping_fee_details
          join_scope(
            <<-JOIN_STRING.strip_heredoc
              LEFT OUTER JOIN spree_shipping_methods
                ON (
                  spree_adjustments.originator_type = 'Spree::ShippingMethod'
                    AND spree_shipping_methods.id = spree_adjustments.originator_id
                )
            JOIN_STRING
          )
        end

        # Includes:
        # * Enterprise fee
        # * Enterprise
        # * Enterprise fee tax category
        def include_enterprise_fee_details
          join_scope(
            <<-JOIN_STRING.strip_heredoc
              LEFT OUTER JOIN enterprise_fees
                ON (
                  spree_adjustments.originator_type = 'EnterpriseFee'
                    AND enterprise_fees.id = spree_adjustments.originator_id
                )
            JOIN_STRING
          )

          join_scope(
            <<-JOIN_STRING.strip_heredoc
              LEFT OUTER JOIN enterprises
                ON (enterprises.id = enterprise_fees.enterprise_id)
            JOIN_STRING
          )

          join_scope(
            <<-JOIN_STRING.strip_heredoc
              LEFT OUTER JOIN spree_tax_categories
                ON (spree_tax_categories.id = enterprise_fees.tax_category_id)
            JOIN_STRING
          )
        end

        # If for order source
        #
        # Includes:
        # * Source order
        # * Distributor
        def include_order_source_details
          join_scope(
            <<-JOIN_STRING.strip_heredoc
              LEFT OUTER JOIN spree_orders AS adjustment_source_orders
                ON (
                  spree_adjustments.adjustable_type = 'Spree::Order'
                    AND adjustment_source_orders.id = spree_adjustments.adjustable_id
                )
            JOIN_STRING
          )

          join_scope(
            <<-JOIN_STRING.strip_heredoc
              LEFT OUTER JOIN enterprises AS adjustment_source_distributors
                ON (adjustment_source_distributors.id = adjustment_source_orders.distributor_id)
            JOIN_STRING
          )
        end

        # If for line item source - Use data only if spree_line_items.id is present
        #
        # Includes:
        # * Line item
        # * Variant
        # * Product
        # * Tax category of product, if enterprise fee tells to inherit
        def include_line_item_source_details
          join_scope(
            <<-JOIN_STRING.strip_heredoc
              LEFT OUTER JOIN spree_line_items
                ON (
                  spree_adjustments.adjustable_type = 'Spree::LineItem'
                    AND spree_line_items.id = spree_adjustments.adjustable_id
                )
            JOIN_STRING
          )

          join_scope(
            <<-JOIN_STRING.strip_heredoc
              LEFT OUTER JOIN spree_variants
                ON (
                  spree_adjustments.adjustable_type = 'Spree::LineItem'
                    AND spree_variants.id = spree_line_items.variant_id
                )
            JOIN_STRING
          )

          join_scope(
            <<-JOIN_STRING.strip_heredoc
              LEFT OUTER JOIN spree_products
                ON (spree_products.id = spree_variants.product_id)
            JOIN_STRING
          )

          join_scope(
            <<-JOIN_STRING.strip_heredoc
              LEFT OUTER JOIN spree_tax_categories AS product_tax_categories
                ON (
                  enterprise_fees.inherits_tax_category IS TRUE
                    AND product_tax_categories.id = spree_products.tax_category_id
                )
            JOIN_STRING
          )
        end

        # If incoming exchange - Use data only if incoming_exchange_variants.id is present
        #
        # Includes:
        # * Incoming exchange
        # * Incoming exchange enterprise
        # * Incoming exchange variant
        def include_incoming_exchange_details
          join_scope(
            <<-JOIN_STRING.strip_heredoc
              LEFT OUTER JOIN
                (
                  exchange_variants AS incoming_exchange_variants
                    LEFT OUTER JOIN exchanges AS incoming_exchanges
                    ON (
                      incoming_exchanges.incoming IS TRUE
                        AND incoming_exchange_variants.exchange_id = incoming_exchanges.id
                    )
                )
                ON (
                  spree_adjustments.adjustable_type = 'Spree::LineItem'
                    AND adjustment_metadata.enterprise_role = 'supplier'
                    AND incoming_exchanges.order_cycle_id = spree_orders.order_cycle_id
                    AND incoming_exchange_variants.id IS NOT NULL
                    AND incoming_exchange_variants.variant_id = spree_line_items.variant_id
                )
            JOIN_STRING
          )

          join_scope(
            <<-JOIN_STRING.strip_heredoc
              LEFT OUTER JOIN enterprises AS incoming_exchange_enterprises
                ON (incoming_exchange_enterprises.id = incoming_exchanges.sender_id)
            JOIN_STRING
          )
        end

        # If outgoing exchange - Use data only if outgoing_exchange_variants.id is present
        #
        # Includes:
        # * Outgoing exchange
        # * Outgoing exchange enterprise
        # * Outgoing exchange variant
        def include_outgoing_exchange_details
          join_scope(
            <<-JOIN_STRING.strip_heredoc
              LEFT OUTER JOIN
                (
                  exchange_variants AS outgoing_exchange_variants
                    LEFT OUTER JOIN exchanges AS outgoing_exchanges
                    ON (
                      outgoing_exchanges.incoming IS NOT TRUE
                        AND outgoing_exchange_variants.exchange_id = outgoing_exchanges.id
                    )
                )
                ON (
                  spree_adjustments.adjustable_type = 'Spree::LineItem'
                    AND adjustment_metadata.enterprise_role = 'distributor'
                    AND outgoing_exchanges.order_cycle_id = spree_orders.order_cycle_id
                    AND outgoing_exchange_variants.id IS NOT NULL
                    AND outgoing_exchange_variants.variant_id = spree_line_items.variant_id
                )
            JOIN_STRING
          )

          join_scope(
            <<-JOIN_STRING.strip_heredoc
              LEFT OUTER JOIN enterprises AS outgoing_exchange_enterprises
                ON (outgoing_exchange_enterprises.id = outgoing_exchanges.receiver_id)
            JOIN_STRING
          )
        end

        def filter_by_date(params)
          filter_scope("spree_orders.completed_at >= ?", params.completed_at_gt) \
            if params.completed_at_gt.present?
          filter_scope("spree_orders.completed_at <= ?", params.completed_at_lt) \
            if params.completed_at_lt.present?
        end

        def filter_by_distribution(params)
          filter_scope(spree_orders: { distributor_id: params.distributor_ids }) \
            if params.distributor_ids.present?
          filter_scope(spree_products: { supplier_id: params.producer_ids }) \
            if params.producer_ids.present?
          filter_scope(spree_orders: { order_cycle_id: params.order_cycle_ids }) \
            if params.order_cycle_ids.present?
        end

        def filter_by_fee(params)
          filter_scope(enterprise_fees: { id: params.enterprise_fee_ids }) \
            if params.enterprise_fee_ids.present?
          filter_scope(spree_shipping_methods: { id: params.shipping_method_ids }) \
            if params.shipping_method_ids.present?
          filter_scope(spree_payment_methods: { id: params.payment_method_ids }) \
            if params.payment_method_ids.present?
        end

        def exclude_groups_with_zero_total
          filter_scope("spree_adjustments.amount != 0")
        end

        def group_data
          chain_to_scope do
            group(
              "enterprise_fees.id",
              "enterprises.id",
              "customers.id",
              "hubs.id",
              "spree_payment_methods.id",
              "spree_shipping_methods.id",
              "adjustment_metadata.enterprise_role",
              "spree_tax_categories.id",
              "product_tax_categories.id",
              "spree_adjustments.adjustable_type",
              "adjustment_source_distributors.id",
              "incoming_exchange_enterprises.id",
              "outgoing_exchange_enterprises.id"
            )
          end
        end

        def select_attributes
          chain_to_scope do
            select(
              <<-JOIN_STRING.strip_heredoc
                SUM(spree_adjustments.amount) AS total_amount,
                  spree_payment_methods.name AS payment_method_name,
                  spree_shipping_methods.name AS shipping_method_name,
                  hubs.name AS hub_name,
                  enterprises.name AS enterprise_name,
                  enterprise_fees.fee_type AS fee_type,
                  TRIM(CONCAT(customers.first_name, ' ', customers.last_name)) AS customer_name,
                  customers.email AS customer_email,
                  enterprise_fees.name AS fee_name,
                  spree_tax_categories.name AS tax_category_name,
                  enterprise_fees.inherits_tax_category AS enterprise_fee_inherits_tax_category,
                  product_tax_categories.name AS product_tax_category_name,
                  adjustment_metadata.enterprise_role AS placement_enterprise_role,
                  spree_adjustments.adjustable_type AS adjustment_adjustable_type,
                  adjustment_source_distributors.name AS adjustment_source_distributor_name,
                  incoming_exchange_enterprises.name AS incoming_exchange_enterprise_name,
                  outgoing_exchange_enterprises.name AS outgoing_exchange_enterprise_name
              JOIN_STRING
            )
          end
        end

        def chain_to_scope(&block)
          @scope = @scope.instance_eval(&block)
          self
        end

        def join_scope(join_string)
          chain_to_scope do
            joins(join_string)
          end
        end

        def filter_scope(*args)
          chain_to_scope do
            where(*args)
          end
        end
      end
    end
  end
end
