module OrderManagement
  module Reports
    module EnterpriseFeeSummary
      class EnterpriseFeeTypeTotalSummarizer
        PAYMENT_METHOD_SOURCE_TYPE = 1
        SHIPPING_METHOD_SOURCE_TYPE = 2
        COORDINATOR_FEE_SOURCE_TYPE = 3
        INCOMING_EXCHANGE_LINE_ITEM_FEE_SOURCE_TYPE = 4
        OUTGOING_EXCHANGE_LINE_ITEM_FEE_SOURCE_TYPE = 5
        INCOMING_EXCHANGE_ORDER_FEE_SOURCE_TYPE = 6
        OUTGOING_EXCHANGE_ORDER_FEE_SOURCE_TYPE = 7

        attr_accessor :data

        def initialize(data)
          @data = data
        end

        def fee_type
          case adjustment_source_type
            when PAYMENT_METHOD_SOURCE_TYPE
              i18n_translate("fee_type.payment_method")
            when SHIPPING_METHOD_SOURCE_TYPE
              i18n_translate("fee_type.shipping_method")
            else
              data["fee_type"].try(:capitalize)
            end
        end

        def enterprise_name
          case adjustment_source_type
            when PAYMENT_METHOD_SOURCE_TYPE, SHIPPING_METHOD_SOURCE_TYPE
              data["hub_name"]
            else
              data["enterprise_name"]
            end
        end

        def fee_name
          case adjustment_source_type
            when PAYMENT_METHOD_SOURCE_TYPE
              data["payment_method_name"]
            when SHIPPING_METHOD_SOURCE_TYPE
              data["shipping_method_name"]
            else
              data["fee_name"]
            end
        end

        def customer_name
          data["customer_name"]
        end

        def fee_placement
          case adjustment_source_type
            when PAYMENT_METHOD_SOURCE_TYPE, SHIPPING_METHOD_SOURCE_TYPE
              nil
            else
              i18n_translate("fee_placements.#{data['placement_enterprise_role']}")
            end
        end

        def fee_calculated_on_transfer_through_name
          case adjustment_source_type
            when COORDINATOR_FEE_SOURCE_TYPE
              i18n_translate("fee_calculated_on_transfer_through_all")
            when INCOMING_EXCHANGE_LINE_ITEM_FEE_SOURCE_TYPE
              data["incoming_exchange_enterprise_name"]
            when OUTGOING_EXCHANGE_LINE_ITEM_FEE_SOURCE_TYPE
              data["outgoing_exchange_enterprise_name"]
            when INCOMING_EXCHANGE_ORDER_FEE_SOURCE_TYPE, OUTGOING_EXCHANGE_ORDER_FEE_SOURCE_TYPE
              i18n_translate("fee_calculated_on_transfer_through_entire_orders",
                             distributor: data["adjustment_source_distributor_name"])
            end
        end

        def tax_category_name
          case adjustment_source_type
            when PAYMENT_METHOD_SOURCE_TYPE
              nil
            when SHIPPING_METHOD_SOURCE_TYPE
              i18n_translate("tax_category_name.shipping_instance_rate")
            when COORDINATOR_FEE_SOURCE_TYPE
              data["tax_category_name"] \
                || (i18n_translate("tax_category_various") if enterprise_fee_inherits_tax_category?)
            when INCOMING_EXCHANGE_LINE_ITEM_FEE_SOURCE_TYPE, OUTGOING_EXCHANGE_LINE_ITEM_FEE_SOURCE_TYPE
              data["tax_category_name"] || data["product_tax_category_name"]
            when INCOMING_EXCHANGE_ORDER_FEE_SOURCE_TYPE, OUTGOING_EXCHANGE_ORDER_FEE_SOURCE_TYPE
              data["tax_category_name"] || i18n_translate("tax_category_various")
            end
        end

        def total_amount
          data["total_amount"]
        end

        private

        def adjustment_source_type
          return PAYMENT_METHOD_SOURCE_TYPE if for_payment_method?
          return SHIPPING_METHOD_SOURCE_TYPE if for_shipping_method?
          return COORDINATOR_FEE_SOURCE_TYPE if for_coordinator_fee?
          return INCOMING_EXCHANGE_LINE_ITEM_FEE_SOURCE_TYPE if for_incoming_exchange? && for_line_item_adjustment_source?
          return OUTGOING_EXCHANGE_LINE_ITEM_FEE_SOURCE_TYPE if for_outgoing_exchange? && for_line_item_adjustment_source?
          return INCOMING_EXCHANGE_ORDER_FEE_SOURCE_TYPE if for_incoming_exchange? && for_order_adjustment_source?
          return OUTGOING_EXCHANGE_ORDER_FEE_SOURCE_TYPE if for_outgoing_exchange? && for_order_adjustment_source?
        end

        def for_payment_method?
          data["payment_method_name"].present?
        end

        def for_shipping_method?
          data["shipping_method_name"].present?
        end

        def for_enterprise_fee?
          data["fee_name"].present?
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
          data["adjustment_source_type"] == "Spree::Order"
        end

        def for_line_item_adjustment_source?
          data["adjustment_source_type"] == "Spree::LineItem"
        end

        def enterprise_fee_inherits_tax_category?
          for_enterprise_fee? && data["tax_category_name"].blank? \
            && data["enterprise_fee_inherits_tax_category"] == "t"
        end

        def i18n_translate(translation_key, options = {})
          I18n.t("order_management.reports.enterprise_fee_summary.#{translation_key}", options)
        end
      end
    end
  end
end
