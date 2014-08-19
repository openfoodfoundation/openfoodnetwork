module Spree
  module Admin
    module NavigationHelper
      # Make it so that the Reports admin tab can be enabled/disabled through the cancan
      # :report resource, since it does not have a corresponding resource class (unlike
      # eg. Spree::Product).
      def klass_for_with_sym_fallback(name)
        klass = klass_for_without_sym_fallback(name)
        klass ||= name.singularize.to_sym
        klass = :overview if klass == :dashboard
        klass
      end
      alias_method_chain :klass_for, :sym_fallback
    end
  end
end
