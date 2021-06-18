# frozen_string_literal: true

module OrderManagement
  module Reports
    module EnterpriseFeeSummary
      class ReportService
        attr_accessor :permissions, :parameters

        def initialize(permissions, parameters)
          @permissions = permissions
          @parameters = parameters
        end

        def enterprise_fees_by_customer
          Scope.new.apply_filters(permission_filters).apply_filters(parameters).result
        end

        def list
          enterprise_fee_type_total_list.sort
        end

        private

        def permission_filters
          Parameters.new(order_cycle_ids: permissions.allowed_order_cycles.map(&:id))
        end

        def enterprise_fee_type_total_list
          enterprise_fees_by_customer.map do |total_data|
            summarizer = Summarizer.new(total_data)

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
