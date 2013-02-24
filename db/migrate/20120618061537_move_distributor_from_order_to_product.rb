class MoveDistributorFromOrderToProduct < ActiveRecord::Migration
  class Distributor < ActiveRecord::Base; end
  class Spree::Product < ActiveRecord::Base; end

  def up
    remove_column :spree_orders, :distributor_id

    create_table :distributors_products, :id => false do |t|
      t.references :product
      t.references :distributor
    end

    # Associate all products with the first distributor
    distributor = Distributor.first
    if distributor
      Spree::Product.all.each do |product|
        product.distributors << distributor
      end
    end
  end

  def down
    drop_table :distributors_products
    add_column :spree_orders, :distributor_id, :integer
  end
end
