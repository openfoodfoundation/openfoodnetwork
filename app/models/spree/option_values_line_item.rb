# frozen_string_literal: true

module Spree
  class OptionValuesLineItem < ActiveRecord::Base
    belongs_to :line_item, class_name: 'Spree::LineItem'
    belongs_to :option_value, class_name: 'Spree::OptionValue'
  end
end
