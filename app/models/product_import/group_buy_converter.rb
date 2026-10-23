# frozen_string_literal: true

# This class handles conversion of the group buy fields from a spreadsheet into the values
# stored on the product. Blank cells are removed so they leave the product's existing value
# unchanged, and unrecognised values are kept as they are so that they fail validation.
#
# group_buy            group_buy_unit_size   ->   group_buy   group_buy_unit_size
# 1 / true / yes       10                    ->   true        10.0
# 0 / false / no       nil                   ->   false       (unchanged)

module ProductImport
  class GroupBuyConverter
    ATTRIBUTES = ['group_buy', 'group_buy_unit_size'].freeze

    GROUP_BUY_VALUES = {
      '1' => true, 'true' => true, 'yes' => true,
      '0' => false, 'false' => false, 'no' => false
    }.freeze

    def initialize(attrs)
      @attrs = attrs
      remove_blank_values
      convert_group_buy
      convert_group_buy_unit_size
    end

    def converted_attributes
      @attrs
    end

    private

    def remove_blank_values
      ATTRIBUTES.each do |attr|
        @attrs.delete(attr) if @attrs.key?(attr) && @attrs[attr].blank?
      end
    end

    def convert_group_buy
      return unless @attrs.key?('group_buy')

      value = @attrs['group_buy']
      @attrs['group_buy'] = GROUP_BUY_VALUES.fetch(value.to_s.strip.downcase, value)
    end

    def convert_group_buy_unit_size
      return unless @attrs.key?('group_buy_unit_size')

      value = @attrs['group_buy_unit_size']
      @attrs['group_buy_unit_size'] = Float(value, exception: false) || value
    end
  end
end
