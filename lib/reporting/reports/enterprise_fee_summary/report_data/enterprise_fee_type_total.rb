# frozen_string_literal: true

module Reporting
  module Reports
    module EnterpriseFeeSummary
      module ReportData
        class EnterpriseFeeTypeTotal <
          Reporting::Reports::EnterpriseFeeSummary::Reports::ReportData::Base
          attr_accessor :fee_type, :enterprise_name, :fee_name, :customer_name, :fee_placement,
                        :fee_calculated_on_transfer_through_name, :tax_category_name, :total_amount

          def <=>(other)
            sortable_data <=> other.sortable_data
          end

          def sortable_data
            [
              fee_type,
              enterprise_name,
              fee_name,
              customer_name,
              fee_placement,
              fee_calculated_on_transfer_through_name,
              tax_category_name,
              total_amount
            ].map { |attribute| attribute || "" }
          end
        end
      end
    end
  end
end
