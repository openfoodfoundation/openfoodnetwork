# This migration is an OFN specific migration that enforces an order to have a single shipment at all times
class AddUniquenessOfOrderIdToSpreeShipments < ActiveRecord::Migration
  def change
    destroy_all_but_latest_shipments

    remove_index :spree_shipments, :order_id
    add_index :spree_shipments, :order_id, unique: true
  end

  private

  # Destroy all but the latest shipment in each order
  def destroy_all_but_latest_shipments
    latest_shipments = Spree::Shipment.
      select("order_id, MAX(updated_at) updated_at").
      group(:order_id).
      having("count(*) > 1")

    Spree::Shipment.
      joins("INNER JOIN (#{latest_shipments.to_sql}) latest_shipments ON spree_shipments.order_id=latest_shipments.order_id AND spree_shipments.updated_at != latest_shipments.updated_at").
      destroy_all
  end
end
