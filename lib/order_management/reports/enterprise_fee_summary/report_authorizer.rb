require "open_food_network/reports/report_authorizer"

module OrderManagement
  module Reports
    module EnterpriseFeeSummary
      class ReportAuthorizer < OpenFoodNetwork::Reports::ReportAuthorizer
        def allowed_distributors
          []
        end

        def allowed_producers
          []
        end

        def allowed_order_cycles
          []
        end

        def allowed_enterprise_fees
          []
        end

        def allowed_shipping_methods
          []
        end

        def allowed_payment_methods
          []
        end
      end
    end
  end
end
