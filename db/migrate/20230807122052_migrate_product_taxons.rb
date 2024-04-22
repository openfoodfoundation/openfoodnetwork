class MigrateProductTaxons < ActiveRecord::Migration[7.0]
  def up
    migrate_primary_taxon
  end

  def migrate_primary_taxon
    ActiveRecord::Base.connection.execute(<<-SQL
      UPDATE spree_variants
      SET primary_taxon_id = spree_products.primary_taxon_id
      FROM spree_products
      WHERE spree_variants.product_id = spree_products.id
    SQL
    )
  end
end
