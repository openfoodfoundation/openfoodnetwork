# frozen_string_literal: true

module Api
  module Admin
    class UnitsVariantSerializer < ActiveModel::Serializer
      attributes :id, :full_name, :unit_value, :variant_unit, :variant_unit_scale

      def full_name
        full_name = object.full_name
        object.product.name + (full_name.blank? ? "" : ": #{full_name}")
      end
    end
  end
end
