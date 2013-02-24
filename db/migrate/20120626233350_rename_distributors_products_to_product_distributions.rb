class RenameDistributorsProductsToProductDistributions < ActiveRecord::Migration
  class Spree::ShippingMethod < ActiveRecord::Base; end
  class ProductDistribution < ActiveRecord::Base; end

  def up
    # Convert m2m join table into explicit join model, and add a shipping method relation and timestamps
    rename_table :distributors_products, :product_distributions
    add_column :product_distributions, :id, :primary_key
    change_table :product_distributions do |t|
      t.references :shipping_method
      t.timestamps
    end

    # Set default shipping method on all product distributions
    sm = Spree::ShippingMethod.unscoped.first
    ProductDistribution.update_all(:shipping_method_id => sm.id) if sm
  end

  def down
    change_table :product_distributions do |t|
      t.remove :id
      t.remove :shipping_method_id
      t.remove :created_at, :updated_at
    end
    rename_table :product_distributions, :distributors_products
  end
end
