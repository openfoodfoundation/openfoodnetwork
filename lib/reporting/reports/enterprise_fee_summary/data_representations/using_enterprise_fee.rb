# frozen_string_literal: true

# Different EnterpriseFeeSummary::Scope DB result attributes are checked when dealing with
# enterprise fees that are attached to an order cycle in different ways.
#
# This module provides DB result to report mappings that are common among all rows for enterprise
# fees. These mappings are not complete and should be supplemented with mappings that are specific
# to the way that the enterprise fee is attached to the order cycle.

module Reporting
  module Reports
    module EnterpriseFeeSummary
      module DataRepresentations
        module UsingEnterpriseFee
          include WithI18n

          attr_reader :data

          def initialize(data)
            @data = data
          end

          def fee_type
            data["fee_type"].try(:capitalize)
          end

          def enterprise_name
            data["enterprise_name"]
          end

          def fee_name
            data["fee_name"]
          end

          def fee_placement
            i18n_translate("fee_placements.#{data['placement_enterprise_role']}")
          end
        end
      end
    end
  end
end
