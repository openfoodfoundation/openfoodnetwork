class RemoveMasterVariants < ActiveRecord::Migration[7.0]
  def change
    if ActiveRecord::Base.connection.table_exists? "spree_option_values_variants"
      delete_master_option_values
    end

    handle_master_line_items
    handle_master_exchange_variants
    delete_master_inventory_units
    delete_master_variant_prices
    delete_master_stock_items
    delete_master_variants
  end

  private

  def handle_master_line_items
    ActiveRecord::Base.connection.execute(<<-SQL
      UPDATE spree_variants
      SET is_master = false
      FROM spree_line_items
      WHERE spree_variants.is_master = true
        AND spree_variants.id = spree_line_items.variant_id
    SQL
    )
  end

  def handle_master_exchange_variants
    ActiveRecord::Base.connection.execute(<<-SQL
      UPDATE spree_variants
      SET is_master = false
      FROM exchange_variants
      WHERE spree_variants.is_master = true
        AND spree_variants.id = exchange_variants.variant_id
    SQL
    )
  end

  def delete_master_inventory_units
    ActiveRecord::Base.connection.execute(<<-SQL
      DELETE FROM spree_inventory_units
      USING spree_variants
      WHERE spree_variants.is_master = true
        AND spree_variants.id = spree_inventory_units.variant_id
    SQL
    )
  end

  def delete_master_option_values
    ActiveRecord::Base.connection.execute(<<-SQL
      DELETE FROM spree_option_values_variants
      USING spree_variants
      WHERE spree_variants.is_master = true
        AND spree_variants.id = spree_option_values_variants.variant_id
    SQL
    )
  end

  def delete_master_variant_prices
    ActiveRecord::Base.connection.execute(<<-SQL
      DELETE FROM spree_prices
      USING spree_variants
      WHERE spree_variants.is_master = true
        AND spree_variants.id = spree_prices.variant_id
    SQL
    )
  end

  def delete_master_stock_items
    ActiveRecord::Base.connection.execute(<<-SQL
      DELETE FROM spree_stock_items
      USING spree_variants
      WHERE spree_variants.is_master = true
        AND spree_variants.id = spree_stock_items.variant_id
    SQL
    )
  end

  def delete_master_variants
    ActiveRecord::Base.connection.execute(<<-SQL
      DELETE FROM spree_variants
      WHERE is_master = true
    SQL
    )
  end
end
