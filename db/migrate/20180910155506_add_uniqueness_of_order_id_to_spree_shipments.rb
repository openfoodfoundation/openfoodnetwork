# This migration is an OFN specific migration that enforces an order to have a single shipment at all times
class AddUniquenessOfOrderIdToSpreeShipments < ActiveRecord::Migration
  def change
    Spree::InventoryUnit.connection.schema_cache.clear!
    Spree::InventoryUnit.reset_column_information

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

    shipments_to_delete = Spree::Shipment.
      joins("INNER JOIN (#{latest_shipments.to_sql}) latest_shipments ON spree_shipments.order_id = latest_shipments.order_id AND spree_shipments.updated_at != latest_shipments.updated_at")
    remove_association_to_adjustments(shipments_to_delete)
    shipments_to_delete.destroy_all
  end

  def remove_association_to_adjustments(shipments)
    Spree::Adjustment.
      joins("INNER JOIN (#{shipments.to_sql}) shipments_to_delete ON shipments_to_delete.id = spree_adjustments.source_id and spree_adjustments.source_type = 'Spree::Shipment'").
      update_all(source_id: nil, source_type: nil, originator_id: nil, originator_type: nil, mandatory: nil)
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
      tracking
      number
      order_number
      shipping_method_name
      cost
      state
      shipped_at
      created_at
      updated_at
      address_json
    )
  end

  def shipment_csv_row(shipment)
    [
      shipment.id,
      shipment.tracking,
      shipment.number,
      shipment.order.number,
      shipment.shipping_method.andand.name,
      shipment.cost,
      shipment.state,
      shipment.shipped_at,
      shipment.created_at,
      shipment.updated_at,
      shipment.address.to_json
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
