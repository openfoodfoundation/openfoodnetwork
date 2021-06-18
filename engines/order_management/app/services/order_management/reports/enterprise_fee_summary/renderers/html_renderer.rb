# frozen_string_literal: true

module OrderManagement
  module Reports
    module EnterpriseFeeSummary
      module Renderers
        class HtmlRenderer < ::Reports::Renderers::Base
          def render(context)
            context.instance_variable_set :@renderer, self
            context.render(action: :create, renderer: self)
          end

          def header
            data_row_attributes.map do |attribute|
              header_label(attribute)
            end
          end

          def data_rows
            report_data.list.map do |data|
              data_row_attributes.map do |attribute|
                data.public_send(attribute)
              end
            end
          end

          private

          def data_row_attributes
            [
              :fee_type,
              :enterprise_name,
              :fee_name,
              :customer_name,
              :fee_placement,
              :fee_calculated_on_transfer_through_name,
              :tax_category_name,
              :total_amount
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
