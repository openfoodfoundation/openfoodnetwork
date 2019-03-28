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

    all_duplicated_shipments = Spree::Shipment.
      joins("INNER JOIN (#{latest_shipments.to_sql}) latest_shipments ON spree_shipments.order_id = latest_shipments.order_id")
    backup_to_csv(all_duplicated_shipments)

    Spree::Shipment.
      joins("INNER JOIN (#{latest_shipments.to_sql}) latest_shipments ON spree_shipments.order_id=latest_shipments.order_id AND spree_shipments.updated_at != latest_shipments.updated_at").
      destroy_all
  end

  def backup_to_csv(shipments)
    CSV.open(csv_path, "w") do |csv|
      csv << csv_header_row

      shipments.each do |shipment|
        csv << shipment_csv_row(shipment)
      end
    end
  end

  def csv_header_row
    %w(
      id
      shipment.tracking
      number
      cost
      shipped_at
      order_id
      shipping_method_id
      address_id
      created_at
      updated_at
      state
    )
  end

  def shipment_csv_row(shipment)
    [
      shipment.id,
      shipment.tracking,
      shipment.number,
      shipment.cost,
      shipment.shipped_at,
      shipment.order_id,
      shipment.shipping_method_id,
      shipment.address_id,
      shipment.created_at,
      shipment.updated_at,
      shipment.state
    ]
  end

  def csv_path
    ensure_reports_path_exists
    reports_path.join("duplicated_shipments_backup.csv")
  end

  def reports_path
    Rails.root.join("reports")
  end

  def ensure_reports_path_exists
    Dir.mkdir(reports_path) unless File.exist?(reports_path)
  end
end
