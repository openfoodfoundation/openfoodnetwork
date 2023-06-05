class MigrateMasterImageToProduct < ActiveRecord::Migration[7.0]
  def up
    # Multiple images can be present per variant, ordered by the `position` column.
    # In some cases if the image was deleted and another was added, the numbering can be off,
    # so the positions of the images might be 3,4,5 or 2,3 and the "first" image would be position 2
    # or position 3 in those cases (instead of 1).
    #
    # This finds the image for each variant with the lowest `position` out of the current images and
    # sets it's `position` to 1 (if it's not already 1) to make it easier to operate on the "first" image.
    renumber_first_image

    # Switches the association of the first image for each master variant to it's product
    migrate_master_images
  end

  def renumber_first_image
    ActiveRecord::Base.connection.execute(<<-SQL
      UPDATE spree_assets
      SET position = '1'
      FROM (
        SELECT DISTINCT ON (viewable_id) id, viewable_id, position
        FROM spree_assets
        WHERE spree_assets.viewable_type = 'Spree::Variant'
        ORDER BY viewable_id, position ASC
      ) variant_first_image
      WHERE spree_assets.id = variant_first_image.id
      AND spree_assets.position != '1'
    SQL
    )
  end

  def migrate_master_images
    ActiveRecord::Base.connection.execute(<<-SQL
      UPDATE spree_assets
      SET viewable_type = 'Spree::Product',
          viewable_id = spree_variants.product_id
      FROM spree_variants
      WHERE spree_variants.id = spree_assets.viewable_id
        AND spree_variants.is_master = true
        AND spree_variants.deleted_at IS NULL
        AND spree_assets.viewable_type = 'Spree::Variant'
        AND spree_assets.position = '1'
    SQL
    )
  end
end
