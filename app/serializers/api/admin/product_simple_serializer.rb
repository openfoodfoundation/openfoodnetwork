# frozen_string_literal: true

module Api
  module Admin
    class ProductSimpleSerializer < ActiveModel::Serializer
      attributes :id, :name, :producer_id

      has_many :variants, key: :variants, serializer: Api::Admin::VariantSimpleSerializer

      def producer_id
        object.supplier_id
      end

      def on_hand
        return 0 if object.on_hand.nil?

        object.on_hand
      end

      def price
        object.price.nil? ? '0.0' : object.price
      end
    end
  end
end
