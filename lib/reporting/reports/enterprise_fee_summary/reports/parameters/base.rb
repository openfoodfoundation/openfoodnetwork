# frozen_string_literal: true

module Reporting
  module Reports
    module EnterpriseFeeSummary
      module Reports
        module Parameters
          class Base
            extend ActiveModel::Naming
            extend ActiveModel::Translation
            include ActiveModel::Validations
            include ActiveModel::Validations::Callbacks

            def initialize(attributes = {})
              attributes.each do |key, value|
                public_send("#{key}=", value)
              end
            end

            def self.date_end_before_start_error_message
              i18n_scope = "order_management.reports.enterprise_fee_summary"
              I18n.t("date_end_before_start_error", scope: i18n_scope)
            end

            # The parameters are never persisted.
            def to_key; end

            protected

            def require_valid_datetime_range
              return if completed_at_gt.blank? || completed_at_lt.blank?

              error_message = self.class.date_end_before_start_error_message
              errors.add(:completed_at_lt, error_message) unless completed_at_gt < completed_at_lt
            end
          end
        end
      end
    end
  end
end
