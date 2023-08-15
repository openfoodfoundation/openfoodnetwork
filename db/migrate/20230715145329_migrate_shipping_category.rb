class MigrateShippingCategory < ActiveRecord::Migration[7.0]
  def up
    migrate_shipping_category
  end

  def migrate_shipping_category
    ActiveRecord::Base.connection.execute(<<-SQL
      UPDATE spree_variants
      SET shipping_category_id = spree_products.shipping_category_id
      FROM spree_products
      WHERE spree_variants.product_id = spree_products.id
    SQL
    )
  end
end
