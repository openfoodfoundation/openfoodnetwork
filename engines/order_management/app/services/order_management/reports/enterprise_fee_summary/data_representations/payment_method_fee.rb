module OrderManagement
  module Reports
    module EnterpriseFeeSummary
      module DataRepresentations
        class PaymentMethodFee
          attr_reader :context

          def initialize(context)
            @context = context
          end

          def fee_type
            context.i18n_translate("fee_type.payment_method")
          end

          def enterprise_name
            context.data["hub_name"]
          end

          def fee_name
            context.data["payment_method_name"]
          end

          def fee_placement; end

          def fee_calculated_on_transfer_through_name; end

          def tax_category_name; end
        end
      end
    end
  end
end
