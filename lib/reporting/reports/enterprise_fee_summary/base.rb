# frozen_string_literal: true

module Reporting
  module Reports
    module EnterpriseFeeSummary
      class Base < ReportTemplate
        attr_accessor :permissions, :parameters

        def initialize(user, params = {}, render: false)
          super(user, params, render: render)
          @parameters = Parameters.new(params.fetch(:q, {}))
          @parameters.validate!
          @permissions = Permissions.new(user)
          @parameters.authorize!(@permissions)
        end

        def custom_headers
          data_attributes.map { |attr| [attr, I18n.t("header.#{attr}", scope: i18n_scope)] }.to_h
        end

        def i18n_scope
          "order_management.reports.enterprise_fee_summary.formats.csv"
        end

        def message
          I18n.t("spree.admin.reports.customer_names_message.customer_names_tip")
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
          data_attributes.map { |field|
            [field.to_sym, proc { |data| data.public_send(field) }]
          }.to_h
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
