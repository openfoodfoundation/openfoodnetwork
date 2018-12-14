module OrderManagement
  module Reports
    module EnterpriseFeeSummary
      module ReportData
        class EnterpriseFeeTypeTotals < ::Reports::ReportData::Base
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
