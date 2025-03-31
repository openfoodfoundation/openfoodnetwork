# frozen_string_literal: true

module Api
  module Admin
    class ProductSerializer < ActiveModel::Serializer
      attributes :id, :name, :sku, :inherits_properties, :price, :import_date, :image_url,
                 :thumb_url, :variants

      def variants
        ActiveModel::ArraySerializer.new(
          object.variants,
          each_serializer: Api::Admin::VariantSerializer,
          image: thumb_url,
        )
      end

      def image_url
        object.image&.url(:product) || Spree::Image.default_image_url(:product)
      end

      def thumb_url
        object.image&.url(:mini) || Spree::Image.default_image_url(:mini)
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
