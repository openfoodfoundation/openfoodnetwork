# frozen_string_literal: true

class EnsureSingleProductImage < ActiveRecord::Migration[7.1]
  class SpreeImage < ActiveRecord::Base
    self.table_name = "spree_assets"
    self.inheritance_column = :_type_disabled
  end

  def up
    product_ids = SpreeImage
      .where(viewable_type: "Spree::Product")
      .group(:viewable_id)
      .having("COUNT(*) > 1")
      .pluck(:viewable_id)

    product_ids.each do |product_id|
      images = SpreeImage
        .where(
          viewable_type: "Spree::Product",
          viewable_id: product_id
        )
        .order(:id)

      image_to_keep = images.first

      images.where.not(id: image_to_keep.id).update_all(deleted_at: Time.current)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
