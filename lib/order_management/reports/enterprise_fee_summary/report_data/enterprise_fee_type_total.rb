require "open_food_network/reports/report_data/base"

module OrderManagement
  module Reports
    module EnterpriseFeeSummary
      module ReportData
        class EnterpriseFeeTypeTotal < OpenFoodNetwork::Reports::ReportData::Base
          attr_accessor :fee_type, :enterprise_name, :fee_name, :customer_name, :fee_placement,
                        :fee_calculated_on_transfer_through_name, :tax_category_name, :total_amount
        end
      end
    end
  end
end
