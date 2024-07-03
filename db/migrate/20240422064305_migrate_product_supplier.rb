class MigrateProductSupplier < ActiveRecord::Migration[7.0]
  def up
    ActiveRecord::Base.connection.execute(<<-SQL
      UPDATE spree_variants
      SET supplier_id = spree_products.supplier_id
      FROM spree_products
      WHERE spree_variants.product_id = spree_products.id
    SQL
    )
  end
end
