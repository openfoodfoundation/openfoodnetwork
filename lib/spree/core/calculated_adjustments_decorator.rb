# Maybe we don't need this any more? Commenting out during upgrade process

# module Spree
#   module Core
#     module CalculatedAdjustments
#       module ClassMethods
#         def calculated_adjustments_with_explicit_class_name
#           calculated_adjustments_without_explicit_class_name
#           # Class name is mis-inferred outside of Spree namespace
#           has_one :calculator, as: :calculable, dependent: :destroy, class_name: 'Spree::Calculator'
#         end
#         alias_method_chain :calculated_adjustments, :explicit_class_name
#       end
#     end
#   end
# end
