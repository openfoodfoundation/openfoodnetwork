# frozen_string_literal: true

class UpdateProductNameInLineItems < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  module Spree
    class LineItem < ApplicationRecord
      self.table_name = "spree_line_items"

      belongs_to :variant, -> { with_deleted },
                  class_name: "Spree::Variant",
                  inverse_of: :line_items

      def update_product_name
        self.product_name = variant.product.name
      end
    end
  end

  module Spree
    class Variant < ApplicationRecord
      acts_as_paranoid
      self.table_name = "spree_variants"

      belongs_to :product, -> { with_deleted },
                            touch: true,
                            class_name: 'Spree::Product',
                            optional: false,
                            inverse_of: :variants
      has_many :line_items, inverse_of: :variant, dependent: nil
    end
  end

  module Spree
    class Product < ApplicationRecord
      acts_as_paranoid
      self.table_name = "spree_products"

      has_many :variants, -> { order("spree_variants.id ASC") },
                          class_name: 'Spree::Variant',
                          inverse_of: :product,
                          dependent: :destroy
    end
  end

  def up
    line_items_query = Spree::LineItem.includes(variant: :product).
      where(product_name: [nil, ""])

    line_items_query.in_batches do |batch|
      batch.each do |line_item|
        line_item.update_product_name
        line_item.save!
      end
    end
  end

  def down
    # No need to do anything as in AddProductNameToLineItems
    # the product_name column will be deleted during rollback
  end
end
