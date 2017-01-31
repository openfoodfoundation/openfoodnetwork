module Spree
  Calculator::FlexiRate.class_eval do
    def compute(object)
      sum = 0
      max = self.preferred_max_items.to_i
      items_count = line_items_for(object).map(&:quantity).sum
      items_count.times do |i|
        # check max value to avoid divide by 0 errors
        if (max == 0 && i == 0) || (max > 0) && (i % max == 0)
          sum += self.preferred_first_item.to_f
        else
          sum += self.preferred_additional_item.to_f
        end
      end

      sum
    end
  end
end
