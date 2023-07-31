# frozen_string_literal: false

module Calculator
  class FlexiRate < Spree::Calculator
    preference :first_item,      :decimal, default: 0.0
    preference :additional_item, :decimal, default: 0.0
    preference :max_items,       :integer, default: 0

    validates :preferred_first_item,
              :preferred_additional_item,
              numericality: true

    def self.description
      I18n.t(:flexible_rate)
    end

    def self.available?(_object)
      true
    end

    def compute(object)
      max = preferred_max_items.to_i
      items_count = line_items_for(object).map(&:quantity).sum

      # check max value to avoid divide by 0 errors
      return 0 if max.zero?

      if items_count > max
        compute_for(max - 1)
      elsif items_count <= max
        compute_for(items_count - 1)
      end
    end

    private

    def compute_for(count)
      (count * preferred_additional_item.to_f) + preferred_first_item.to_f
    end
  end
end
