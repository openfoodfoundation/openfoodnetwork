# frozen_string_literal: true

module OrderManagement
  module Reports
    module EnterpriseFeeSummary
      module Renderers
        class CsvRenderer < ::Reports::Renderers::Base
          def render(context)
            context.send_data(generate, filename: filename)
          end

          def generate
            CSV.generate do |csv|
              render_header(csv)

              report_data.list.each do |data|
                render_data_row(csv, data)
              end
            end
          end

          private

          def filename
            timestamp = Time.zone.now.strftime("%Y%m%d")
            "enterprise_fee_summary_#{timestamp}.csv"
          end

          def render_header(csv)
            csv << [
              header_label(:fee_type),
              header_label(:enterprise_name),
              header_label(:fee_name),
              header_label(:customer_name),
              header_label(:fee_placement),
              header_label(:fee_calculated_on_transfer_through_name),
              header_label(:tax_category_name),
              header_label(:total_amount)
            ]
          end

          def render_data_row(csv, data)
            csv << [
              data.fee_type,
              data.enterprise_name,
              data.fee_name,
              data.customer_name,
              data.fee_placement,
              data.fee_calculated_on_transfer_through_name,
              data.tax_category_name,
              data.total_amount
            ]
          end

          def header_label(attribute)
            I18n.t("header.#{attribute}", scope: i18n_scope)
          end

          def i18n_scope
            "order_management.reports.enterprise_fee_summary.formats.csv"
          end
        end
      end
    end
  end
end
