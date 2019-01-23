module OrderManagement
  module Reports
    module EnterpriseFeeSummary
      module DataRepresentations
        module UsingEnterpriseFee
          attr_reader :context

          def initialize(context)
            @context = context
          end

          def fee_type
            context.data["fee_type"].try(:capitalize)
          end

          def enterprise_name
            context.data["enterprise_name"]
          end

          def fee_name
            context.data["fee_name"]
          end

          def fee_placement
            context.i18n_translate("fee_placements.#{context.data['placement_enterprise_role']}")
          end
        end
      end
    end
  end
end
