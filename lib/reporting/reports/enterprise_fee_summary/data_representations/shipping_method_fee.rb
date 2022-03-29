# frozen_string_literal: true

# This module provides EnterpriseFeeSummary::Scope DB result to report mappings for shipping method
# fees.

module Reporting
  module Reports
    module EnterpriseFeeSummary
      module DataRepresentations
        class ShippingMethodFee
          include WithI18n

          attr_reader :data

          def initialize(data)
            @data = data
          end

          def fee_type
            i18n_translate("fee_type.shipping_method")
          end

          def enterprise_name
            data["hub_name"]
          end

          def fee_name
            data["shipping_method_name"]
          end

          def fee_placement; end

          def fee_calculated_on_transfer_through_name; end

          def tax_category_name
            i18n_translate("tax_category_name.shipping_instance_rate")
          end
        end
      end
    end
  end
end
