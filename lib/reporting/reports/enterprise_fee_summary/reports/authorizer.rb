# frozen_string_literal: true

module Reporting
  module Reports
    module EnterpriseFeeSummary
      module Reports
        class Authorizer
          attr_accessor :parameters, :permissions

          def initialize(parameters, permissions)
            @parameters = parameters
            @permissions = permissions
          end

          def self.parameter_not_allowed_error_message
            i18n_scope = "order_management.reports.enterprise_fee_summary"
            I18n.t("parameter_not_allowed_error", scope: i18n_scope)
          end

          private

          def require_ids_allowed(array, allowed_objects)
            error_klass = Reporting::Reports::EnterpriseFeeSummary::ParameterNotAllowedError
            error_message = self.class.parameter_not_allowed_error_message
            ids_allowed = (array - allowed_objects.map(&:id).map(&:to_s)).blank?

            raise error_klass, error_message unless ids_allowed
          end
        end
      end
    end
  end
end
