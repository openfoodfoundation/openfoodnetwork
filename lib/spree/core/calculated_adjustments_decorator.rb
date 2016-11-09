module Spree
  module Core
    module CalculatedAdjustments
      class << self
        def included_with_explicit_class_name(klass)
          included_without_explicit_class_name(klass)

          klass.class_eval do
            has_one :calculator, as: :calculable, dependent: :destroy, class_name: 'Spree::Calculator'
          end
        end
        alias_method_chain :included, :explicit_class_name
      end
    end
  end
end
