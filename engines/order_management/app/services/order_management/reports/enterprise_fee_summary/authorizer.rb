module OrderManagement
  module Reports
    module EnterpriseFeeSummary
      class Authorizer < ::Reports::Authorizer
        def self.parameter_not_allowed_error_message
          i18n_scope = "order_management.reports.enterprise_fee_summary"
          I18n.t("parameter_not_allowed_error", scope: i18n_scope)
        end

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
          error_klass = ::Reports::Authorizer::ParameterNotAllowedError
          error_message = self.class.parameter_not_allowed_error_message
          ids_allowed = (array - allowed_objects.map(&:id).map(&:to_s)).blank?

          raise error_klass, error_message unless ids_allowed
        end
      end
    end
  end
end
