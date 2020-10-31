# frozen_string_literal: true

module Api
  module Admin
    class LineItemSerializer < ActiveModel::Serializer
      attributes :id, :quantity, :max_quantity, :price, :supplier, :final_weight_volume,
                 :units_product, :units_variant

      has_one :order, serializer: Api::Admin::IdSerializer

      def supplier
        { id: object.product.supplier_id }
      end

      def units_product
        Api::Admin::UnitsProductSerializer.new(object.product).serializable_hash
      end

      def units_variant
        Api::Admin::UnitsVariantSerializer.new(object.variant).serializable_hash
      end

      def final_weight_volume
        object.final_weight_volume.to_f
      end

      def max_quantity
        return object.quantity unless object.max_quantity.present? &&
                                      object.max_quantity > object.quantity

        object.max_quantity
      end
    end
  end
end
