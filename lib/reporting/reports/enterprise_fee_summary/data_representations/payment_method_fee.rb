# frozen_string_literal: true

# This module provides EnterpriseFeeSummary::Scope DB result to report mappings for payment method
# fees.

module Reporting
  module Reports
    module EnterpriseFeeSummary
      module DataRepresentations
        class PaymentMethodFee
          include WithI18n

          attr_reader :data

          def initialize(data)
            @data = data
          end

          def fee_type
            i18n_translate("fee_type.payment_method")
          end

          def enterprise_name
            data["hub_name"]
          end

          def fee_name
            data["payment_method_name"]
          end

          def fee_placement; end

          def fee_calculated_on_transfer_through_name; end

          def tax_category_name; end
        end
      end
    end
  end
end
