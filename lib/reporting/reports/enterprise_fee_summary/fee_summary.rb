# frozen_string_literal: true

module Reporting
  module Reports
    module EnterpriseFeeSummary
      class FeeSummary < ReportTemplate
        attr_accessor :permissions, :parameters

        def initialize(user, params = {}, render: false)
          super
          @parameters = Parameters.new(params.fetch(:q, {}))
          @parameters.validate!
          @permissions = Permissions.new(user)
          @parameters.authorize!(@permissions)
        end

        def custom_headers
          data_attributes.index_with { |attr| I18n.t("header.#{attr}", scope: i18n_scope) }
        end

        def i18n_scope
          "order_management.reports.enterprise_fee_summary.formats.csv"
        end

        def message
          I18n.t("spree.admin.reports.hidden_customer_details_tip")
        end

        def query_result
          enterprise_fee_type_total_list.sort
        end

        def data_attributes
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

        # This report calculate data in a different way, so we just encapsulate the result
        # in the columns method
        def columns
          data_attributes.to_h { |field|
            [field.to_sym, proc { |data| data.public_send(field) }]
          }
        end

        private

        def enterprise_fees_by_customer
          if parameters.order_cycle_ids.empty?
            # Always restrict to permitted order cycles
            parameters.order_cycle_ids = permissions.allowed_order_cycles.map(&:id)
          end
          Scope.new.apply_filters(parameters).result
        end

        def enterprise_fee_type_total_list
          enterprise_fees_by_customer.map do |total_data|
            summarizer = Summarizer.new(total_data)

            ReportData::EnterpriseFeeTypeTotal.new.tap do |total|
              data_attributes.each do |attribute|
                total.public_send("#{attribute}=", summarizer.public_send(attribute))
              end
            end
          end
        end
      end
    end
  end
end
