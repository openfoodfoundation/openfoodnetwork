# frozen_string_literal: true

module Api
  module Admin
    class ProductSerializer < ActiveModel::Serializer
      attributes :id, :name, :sku, :variant_unit, :variant_unit_scale, :variant_unit_name,
                 :inherits_properties, :on_hand, :price, :available_on, :permalink_live,
                 :tax_category_id, :import_date, :image_url, :thumb_url

      has_one :supplier, key: :producer_id, embed: :id
      has_one :primary_taxon, key: :category_id, embed: :id
      has_many :variants, key: :variants, serializer: Api::Admin::VariantSerializer
      has_one :master, serializer: Api::Admin::VariantSerializer

      def image_url
        object.images.first&.url(:product) || "/noimage/product.png"
      end

      def thumb_url
        object.images.first&.url(:mini) || "/noimage/mini.png"
      end

      def on_hand
        return 0 if object.on_hand.nil?

        object.on_hand
      end

      def price
        object.price.nil? ? '0.0' : object.price
      end

      def available_on
        object.available_on.blank? ? "" : object.available_on.strftime("%F %T")
      end

      def permalink_live
        object.permalink
      end
    end
  end
end
