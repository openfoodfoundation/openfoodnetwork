require "open_food_network/reports/report_data/base"

module OrderManagement
  module Reports
    module EnterpriseFeeSummary
      module ReportData
        class EnterpriseFeeTypeTotals < OpenFoodNetwork::Reports::ReportData::Base
          attr_accessor :list

          def initialize(*args)
            @list = []

            super(*args)
          end
        end
      end
    end
  end
end
