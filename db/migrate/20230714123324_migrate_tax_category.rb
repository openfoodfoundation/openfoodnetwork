class MigrateTaxCategory < ActiveRecord::Migration[7.0]
  def up
    migrate_tax_category
  end

  def migrate_tax_category
    ActiveRecord::Base.connection.execute(<<-SQL
      UPDATE spree_variants
      SET tax_category_id = spree_products.tax_category_id
      FROM spree_products
      WHERE spree_variants.product_id = spree_products.id
    SQL
    )
  end
end
