class MoveDistributorFromOrderToProduct < ActiveRecord::Migration
  def change
    remove_column :spree_orders, :distributor_id
    add_column :spree_products, :distributor_id, :integer
    Spree::Order.reset_column_information
    Spree::Product.reset_column_information

    # Associate all products with the first distributor so they'll be valid
    distributor = Spree::Distributor.first
    Spree::Product.update_all("distributor_id = #{distributor.id}") if distributor
  end
end
