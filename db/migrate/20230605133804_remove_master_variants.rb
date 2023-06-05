class RemoveMasterVariants < ActiveRecord::Migration[7.0]
  def change
    if ActiveRecord::Base.connection.table_exists? "spree_option_values_variants"
      delete_master_option_values
    end

    delete_master_variant_prices
    delete_master_variants
  end

  private

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

  def delete_master_variants
    ActiveRecord::Base.connection.execute(<<-SQL
      DELETE FROM spree_variants
      WHERE is_master = true
    SQL
    )
  end
end
