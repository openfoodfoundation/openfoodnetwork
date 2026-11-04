# frozen_string_literal: true

module Api
  module Admin
    class UnitsVariantSerializer < ActiveModel::Serializer
      attributes :id, :full_name, :unit_value, :variant_unit, :variant_unit_scale

      def full_name
        product_name = line_item&.full_product_name || object.product.name
        variant_name = line_item&.full_variant_name || object.full_name
        product_name + (variant_name.blank? ? "" : ": #{variant_name}")
      end

      private

      def line_item
        options[:line_item]
      end
    end
  end
end
