module OrderManagement
  module Reports
    module EnterpriseFeeSummary
      module DataRepresentations
        class CoordinatorFee
          include UsingEnterpriseFee

          def fee_calculated_on_transfer_through_name
            context.i18n_translate("fee_calculated_on_transfer_through_all")
          end

          def tax_category_name
            return context.data["tax_category_name"] if context.data["tax_category_name"].present?
            context.i18n_translate("tax_category_various") if inherits_tax_category?
          end

          def inherits_tax_category?
            context.data["enterprise_fee_inherits_tax_category"] == "t"
          end
        end
      end
    end
  end
end
