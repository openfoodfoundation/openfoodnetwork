# This migration comes from spree (originally 20130228164411)
class RemoveOnDemandFromProductAndVariant < ActiveRecord::Migration
  def change
    remove_column :spree_products, :on_demand
    # we are removing spree_variants.on_demand in a later migration
  end
end
