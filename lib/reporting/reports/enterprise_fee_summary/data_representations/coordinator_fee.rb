# frozen_string_literal: true

# This module provides EnterpriseFeeSummary::Scope DB result to report mappings for coordinator fees
# in an order cycle.

module Reporting
  module Reports
    module EnterpriseFeeSummary
      module DataRepresentations
        class CoordinatorFee
          include UsingEnterpriseFee

          def fee_calculated_on_transfer_through_name
            i18n_translate("fee_calculated_on_transfer_through_all")
          end

          def tax_category_name
            return data["tax_category_name"] if data["tax_category_name"].present?

            i18n_translate("tax_category_various") if inherits_tax_category?
          end

          def inherits_tax_category?
            data["enterprise_fee_inherits_tax_category"]
          end
        end
      end
    end
  end
end
