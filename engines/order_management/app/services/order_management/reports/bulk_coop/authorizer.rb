module OrderManagement
  module Reports
    module BulkCoop
      class Authorizer < ::Reports::Authorizer
        def self.parameter_not_allowed_error_message
          i18n_scope = "order_management.reports.enterprise_fee_summary"
          I18n.t("parameter_not_allowed_error", scope: i18n_scope)
        end

        def authorize!
          require_ids_allowed(parameters.distributor_ids, permissions.allowed_distributors)
        end
      end
    end
  end
end
