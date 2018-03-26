require 'spree/localized_number'

module Spree
  Calculator::FlexiRate.class_eval do
    extend Spree::LocalizedNumber

    localize_number :preferred_first_item,
    :preferred_additional_item

    def self.description
      I18n.t(:flexible_rate)
    end

    def compute(object)
      sum = 0
      max = self.preferred_max_items.to_i
      items_count = line_items_for(object).map(&:quantity).sum      
      # check max value to avoid divide by 0 errors
      unless max == 0
        if items_count > max
          sum += (max - 1) * self.preferred_additional_item.to_f + self.preferred_first_item.to_f
        elsif items_count <= max
          sum += (items_count - 1) * self.preferred_additional_item.to_f + self.preferred_first_item.to_f
        end
      end

      sum
    end
  end
end
