module OrderManagement
  module Reports
    module EnterpriseFeeSummary
      class EnterpriseFeeTypeTotalSummarizer
        attr_accessor :data

        def initialize(data)
          @data = data
        end

        def fee_type
          if for_payment_method?
            i18n_translate("fee_type.payment_method")
          else
            data["fee_type"].try(:capitalize)
          end
        end

        def enterprise_name
          if for_payment_method?
            data["payment_hub_name"]
          else
            data["enterprise_name"]
          end
        end

        def fee_name
          if for_payment_method?
            data["payment_method_name"]
          else
            data["fee_name"]
          end
        end

        def customer_name
          data["customer_name"]
        end

        def fee_placement
          return if for_payment_method?

          i18n_translate("fee_placements.#{data['placement_enterprise_role']}")
        end

        def fee_calculated_on_transfer_through_name
          return if for_payment_method?

          transfer_through_all_string = i18n_translate("fee_calculated_on_transfer_through_all")

          data["incoming_exchange_enterprise_name"] || data["outgoing_exchange_enterprise_name"] ||
            (transfer_through_all_string if data["placement_enterprise_role"] == "coordinator")
        end

        def tax_category_name
          return if for_payment_method?

          data["tax_category_name"] || data["product_tax_category_name"]
        end

        def total_amount
          data["total_amount"]
        end

        private

        def for_payment_method?
          data["payment_method_name"].present?
        end

        def i18n_translate(translation_key)
          I18n.t("order_management.reports.enterprise_fee_summary.#{translation_key}")
        end
      end
    end
  end
end
