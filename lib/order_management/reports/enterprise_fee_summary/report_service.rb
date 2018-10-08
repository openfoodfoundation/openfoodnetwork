require "order_management/reports/enterprise_fee_summary/scope"
require "order_management/reports/enterprise_fee_summary/enterprise_fee_type_total_summarizer"
require "order_management/reports/enterprise_fee_summary/report_data/enterprise_fee_type_totals"
require "order_management/reports/enterprise_fee_summary/report_data/enterprise_fee_type_total"

module OrderManagement
  module Reports
    module EnterpriseFeeSummary
      class ReportService
        delegate :render, :filename, to: :renderer

        attr_accessor :parameters, :renderer_klass

        def initialize(parameters, renderer_klass)
          @parameters = parameters
          @renderer_klass = renderer_klass
        end

        def enterprise_fees_by_customer
          Scope.new.all
        end

        def enterprise_fee_type_totals
          ReportData::EnterpriseFeeTypeTotals.new(list: enterprise_fee_type_total_list.sort)
        end

        private

        def renderer
          @renderer ||= renderer_klass.new(self)
        end

        def enterprise_fee_type_total_list
          enterprise_fees_by_customer.map do |total_data|
            summarizer = EnterpriseFeeTypeTotalSummarizer.new(total_data)

            ReportData::EnterpriseFeeTypeTotal.new.tap do |total|
              enterprise_fee_type_summarizer_to_total_attributes.each do |attribute|
                total.public_send("#{attribute}=", summarizer.public_send(attribute))
              end
            end
          end
        end

        def enterprise_fee_type_summarizer_to_total_attributes
          [
            :fee_type, :enterprise_name, :fee_name, :customer_name, :fee_placement,
            :fee_calculated_on_transfer_through_name, :tax_category_name, :total_amount
          ]
        end
      end
    end
  end
end
