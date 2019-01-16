module OrderManagement
  module Reports
    module EnterpriseFeeSummary
      class EnterpriseFeeTypeTotalSummarizer
        PAYMENT_METHOD_SOURCE_TYPE = 1
        SHIPPING_METHOD_SOURCE_TYPE = 2
        COORDINATOR_FEE_SOURCE_TYPE = 3
        INCOMING_EXCHANGE_LINE_ITEM_FEE_SOURCE_TYPE = 4
        OUTGOING_EXCHANGE_LINE_ITEM_FEE_SOURCE_TYPE = 5

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
            end
        end

        def tax_category_name
          case adjustment_source_type
            when PAYMENT_METHOD_SOURCE_TYPE
              nil
            when SHIPPING_METHOD_SOURCE_TYPE
              i18n_translate("tax_category_name.shipping_instance_rate")
            else
              data["tax_category_name"] || data["product_tax_category_name"]
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
          return INCOMING_EXCHANGE_LINE_ITEM_FEE_SOURCE_TYPE if for_incoming_exchange?
          return OUTGOING_EXCHANGE_LINE_ITEM_FEE_SOURCE_TYPE if for_outgoing_exchange?
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

        def i18n_translate(translation_key)
          I18n.t("order_management.reports.enterprise_fee_summary.#{translation_key}")
        end
      end
    end
  end
end
