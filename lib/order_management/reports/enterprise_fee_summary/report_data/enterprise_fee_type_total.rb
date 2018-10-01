require "open_food_network/reports/report_data/base"

module OrderManagement
  module Reports
    module EnterpriseFeeSummary
      module ReportData
        class EnterpriseFeeTypeTotal < OpenFoodNetwork::Reports::ReportData::Base
          attr_accessor :fee_type, :enterprise_name, :fee_name, :customer_name, :fee_placement,
                        :fee_calculated_on_transfer_through_name, :tax_category_name, :total_amount

          def <=>(other)
            self.class.sortable_data(self) <=> self.class.sortable_data(other)
          end

          def self.sortable_data(instance)
            [
              instance.fee_type,
              instance.enterprise_name,
              instance.fee_name,
              instance.customer_name,
              instance.fee_placement,
              instance.fee_calculated_on_transfer_through_name,
              instance.tax_category_name,
              instance.total_amount
            ]
          end
        end
      end
    end
  end
end
