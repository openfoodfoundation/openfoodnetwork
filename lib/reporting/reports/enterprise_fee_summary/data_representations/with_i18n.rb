# frozen_string_literal: true

module Reporting
  module Reports
    module EnterpriseFeeSummary
      module DataRepresentations
        module WithI18n
          private

          def i18n_translate(translation_key, options = {})
            I18n.t("order_management.reports.enterprise_fee_summary.#{translation_key}", **options)
          end
        end
      end
    end
  end
end
