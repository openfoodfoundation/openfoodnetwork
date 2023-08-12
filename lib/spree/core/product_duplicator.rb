# frozen_string_literal: true

module Spree
  module Core
    class ProductDuplicator
      attr_accessor :product

      def initialize(product)
        @product = product
      end

      def duplicate
        new_product = duplicate_product
        new_product.save!
        new_product
      end

      protected

      def duplicate_product
        product.dup.tap do |new_product|
          new_product.name = "COPY OF #{product.name}"
          new_product.sku = ""
          new_product.created_at = nil
          new_product.deleted_at = nil
          new_product.updated_at = nil
          new_product.unit_value = true
          new_product.product_properties = reset_properties
          new_product.image = duplicate_image(product.image) if product.image
          new_product.variants = duplicate_variants
        end
      end

      def duplicate_variants
        product.variants.map do |variant|
          duplicate_variant(variant)
        end
      end

      def duplicate_variant(variant)
        variant.dup.tap do |new_variant|
          new_variant.sku = ""
          new_variant.deleted_at = nil
          new_variant.images = variant.images.map { |image| duplicate_image image }
          new_variant.price = variant.price
          new_variant.currency = variant.currency
        end
      end

      def duplicate_image(image)
        new_image = image.dup
        new_image.attachment.attach(image.attachment_blob)
        new_image
      end

      def reset_properties
        product.product_properties.map do |prop|
          prop.dup.tap do |new_prop|
            new_prop.created_at = nil
            new_prop.updated_at = nil
          end
        end
      end
    end
  end
end
