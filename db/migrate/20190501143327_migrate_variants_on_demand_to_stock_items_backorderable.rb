class MigrateVariantsOnDemandToStockItemsBackorderable < ActiveRecord::Migration[4.2]
  def up
    # We use SQL directly here to avoid going through VariantStock.on_demand and VariantStock.on_demand=
    sql = "update spree_stock_items set backorderable = (select on_demand from spree_variants where spree_variants.id = spree_stock_items.variant_id)"
    ActiveRecord::Base.connection.execute(sql)

    remove_column :spree_variants, :on_demand
  end

  def down
    add_column :spree_variants, :on_demand, :boolean, :default => false

    sql = "update spree_variants set on_demand = (select backorderable from spree_stock_items where spree_variants.id = spree_stock_items.variant_id)"
    ActiveRecord::Base.connection.execute(sql)
  end
end
