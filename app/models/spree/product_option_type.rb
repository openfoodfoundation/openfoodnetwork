# frozen_string_literal: true

module Spree
  class ProductOptionType < ActiveRecord::Base
    after_destroy :remove_option_values

    belongs_to :product, class_name: 'Spree::Product'
    belongs_to :option_type, class_name: 'Spree::OptionType'
    acts_as_list scope: :product

    def remove_option_values
      product.variants_including_master.each do |variant|
        option_values = variant.option_values.where(option_type_id: option_type)
        variant.option_values.destroy(*option_values)
      end
    end
  end
end
