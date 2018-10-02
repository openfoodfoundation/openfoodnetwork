module OrderManagement
  module Reports
    module EnterpriseFeeSummary
      class EnterpriseFeeTypeTotalSummarizer
        attr_accessor :data

        def initialize(data)
          @data = data
        end

        def fee_type
          data["fee_type"].capitalize if data["fee_type"]
        end

        def enterprise_name
          data["enterprise_name"]
        end

        def fee_name
          data["fee_name"]
        end

        def customer_name
          data["customer_name"]
        end

        def fee_placement
          i18n_translate("fee_placements.#{data['placement_enterprise_role']}")
        end

        def fee_calculated_on_transfer_through_name
          transfer_through_all_string = i18n_translate("fee_calculated_on_transfer_through_all")

          data["incoming_exchange_enterprise_name"] || data["outgoing_exchange_enterprise_name"] ||
            (transfer_through_all_string if data["placement_enterprise_role"] == "coordinator")
        end

        def tax_category_name
          data["tax_category_name"] || data["product_tax_category_name"]
        end

        def total_amount
          data["total_amount"]
        end

        private

        def i18n_translate(translation_key)
          I18n.t("order_management.reports.enterprise_fee_summary.#{translation_key}")
        end
      end
    end
  end
end
