require "open_food_network/reports/authorizer"

module OrderManagement
  module Reports
    module EnterpriseFeeSummary
      class Authorizer < OpenFoodNetwork::Reports::Authorizer
        def authorize!
          authorize_by_distribution!
          authorize_by_fee!
        end

        private

        def authorize_by_distribution!
          require_ids_allowed(parameters.order_cycle_ids, permissions.allowed_order_cycles)
          require_ids_allowed(parameters.distributor_ids, permissions.allowed_distributors)
          require_ids_allowed(parameters.producer_ids, permissions.allowed_producers)
        end

        def authorize_by_fee!
          require_ids_allowed(parameters.enterprise_fee_ids, permissions.allowed_enterprise_fees)
          require_ids_allowed(parameters.shipping_method_ids, permissions.allowed_shipping_methods)
          require_ids_allowed(parameters.payment_method_ids, permissions.allowed_payment_methods)
        end

        def require_ids_allowed(array, allowed_objects)
          raise OpenFoodNetwork::Reports::Authorizer::ParameterNotAllowedError \
            if (array - allowed_objects.map(&:id).map(&:to_s)).any?
        end
      end
    end
  end
end
