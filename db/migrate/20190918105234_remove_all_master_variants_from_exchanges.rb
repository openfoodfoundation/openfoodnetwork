class RemoveAllMasterVariantsFromExchanges < ActiveRecord::Migration[4.2]
  def up
    # 1. We add standard variants of the products of "lonely masters" into the Exchanges where the master variants are lonely
    match_master_variants

    # 2. We delete all master variants from Exchanges
    delete_master_variants
  end

  def down
  end

  private

  def match_master_variants
    # Master variants that are distributed in Exchanges and their product doesnt have any other variant in those Exchanges
    lonely_masters_sql = "
      SELECT e.id exchange_id, v.id master_variant_id
      FROM exchanges e
      JOIN exchange_variants ev ON (e.id = ev.exchange_id)
      JOIN spree_variants v ON (ev.variant_id = v.id)
      WHERE v.is_master = true
      AND not exists (SELECT 1
                      FROM exchanges e_std
                      JOIN exchange_variants ev_std ON (e_std.id = ev_std.exchange_id)
                      JOIN spree_variants v_std ON (ev_std.variant_id = v_std.id)
                      WHERE v_std.is_master = false AND e.order_cycle_id = e_std.order_cycle_id)"

    # List of all Master Variant IDs with respective max (latest) Standard Variant ID
    latest_standard_variants_sql = "
      SELECT v_master.id master_variant_id, max(v.id) standard_variant_id
      FROM spree_variants v
      JOIN spree_variants v_master ON (v.product_id = v_master.product_id and v_master.is_master = true)
      WHERE v.is_master = false
      GROUP BY v_master.id"

    # Insert latest standard variant of each lonely_master into the Exchanges where the lonely_masters are
    execute(
      "INSERT INTO exchange_variants (exchange_id, variant_id, created_at, updated_at)
      SELECT lonely_masters.exchange_id, latest_standard_variants.standard_variant_id, now(), now()
      FROM (#{lonely_masters_sql}) lonely_masters
      JOIN (#{latest_standard_variants_sql}) latest_standard_variants on (lonely_masters.master_variant_id = latest_standard_variants.master_variant_id)" )
  end

  def delete_master_variants
    execute("
      DELETE
      FROM exchange_variants ev
      USING spree_variants v
      WHERE ev.variant_id = v.id
        AND v.is_master = true")
  end
end
