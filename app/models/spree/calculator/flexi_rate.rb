# frozen_string_literal: false

require_dependency 'spree/calculator'
require 'spree/localized_number'

module Spree
  module Calculator
    class FlexiRate < Calculator
      extend Spree::LocalizedNumber

      preference :first_item,      :decimal, default: 0.0
      preference :additional_item, :decimal, default: 0.0
      preference :max_items,       :integer, default: 0
      preference :currency,        :string,  default: Spree::Config[:currency]

      localize_number :preferred_first_item,
                      :preferred_additional_item

      def self.description
        I18n.t(:flexible_rate)
      end

      def self.available?(_object)
        true
      end

      def compute(object)
        sum = 0
        max = preferred_max_items.to_i
        items_count = line_items_for(object).map(&:quantity).sum
        # check max value to avoid divide by 0 errors
        unless max == 0
          if items_count > max
            sum += (max - 1) * preferred_additional_item.to_f + preferred_first_item.to_f
          elsif items_count <= max
            sum += (items_count - 1) * preferred_additional_item.to_f + preferred_first_item.to_f
          end
        end

        sum
      end
    end
  end
end
