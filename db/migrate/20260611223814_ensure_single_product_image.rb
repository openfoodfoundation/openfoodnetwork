# frozen_string_literal: true

class EnsureSingleProductImage < ActiveRecord::Migration[7.1]
  class SpreeImage < ActiveRecord::Base
    self.table_name = "spree_assets"
    self.inheritance_column = :_type_disabled
  end

  class SpreeProduct < ActiveRecord::Base
    self.table_name = "spree_products"
    has_one :image, class_name: "SpreeImage", foreign_key: "viewable_id"
  end

  def up
    product_ids = SpreeImage
      .where(viewable_type: "Spree::Product")
      .group(:viewable_id)
      .having("COUNT(*) > 1")
      .pluck(:viewable_id)
    product_ids.each_slice(1000) do |batch|
      products = SpreeProduct.includes(:image).where(id: batch)
      products.each do |product|
        image_to_keep = product.image
        SpreeImage.where(
          viewable_type: "Spree::Product",
          viewable_id: product.id
        ).where.not(id: image_to_keep.id)
          .update_all(deleted_at: Time.current)
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
