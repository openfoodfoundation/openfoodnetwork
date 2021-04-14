class ReplaceHardDeletedPrices < ActiveRecord::Migration[4.2]
  def up
    ActiveRecord::Base.connection.execute(
      "INSERT into spree_prices (variant_id, amount, currency, deleted_at)
      SELECT spree_variants.id, '0.00', (SELECT value FROM spree_preferences WHERE key = 'spree/app_configuration/currency'), now()
      FROM spree_variants
      LEFT OUTER JOIN spree_prices ON (spree_variants.id = spree_prices.variant_id)
      WHERE spree_prices.id IS NULL;"
    )
  end
end
