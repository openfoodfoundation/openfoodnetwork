class RemoveDeletedVariantsFromOrderCycles < ActiveRecord::Migration
  def up
    evs = ExchangeVariant.joins(:variant).where('spree_variants.deleted_at IS NOT NULL')
    say "Removing #{evs.count} deleted variants from order cycles..."
    evs.destroy_all
  end

  def down
  end
end
