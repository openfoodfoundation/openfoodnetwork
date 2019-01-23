module OrderManagement
  module Reports
    module EnterpriseFeeSummary
      module DataRepresentations
        class ExchangeOrderFee < UsingEnterpriseFee
          def fee_calculated_on_transfer_through_name
            context.i18n_translate("fee_calculated_on_transfer_through_entire_orders",
                                   distributor: context.data["adjustment_source_distributor_name"])
          end

          def tax_category_name
            context.data["tax_category_name"] || context.i18n_translate("tax_category_various")
          end
        end
      end
    end
  end
end
