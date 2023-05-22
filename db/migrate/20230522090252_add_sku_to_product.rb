class AddSkuToProduct < ActiveRecord::Migration[7.0]
  def up
    add_column :spree_products, :sku, :string, limit: 255, default: "", null: false

    migrate_master_sku
  end

  def down
    remove_column :spree_products, :sku
  end

  private

  def migrate_master_sku
    ActiveRecord::Base.connection.execute(<<-SQL
      UPDATE spree_products
      SET sku = spree_variants.sku
      FROM spree_variants
      WHERE spree_variants.product_id = spree_products.id
        AND spree_variants.is_master = true
    SQL
    )
  end
end
