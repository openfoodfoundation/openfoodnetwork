class AddOrderToAdjustments < ActiveRecord::Migration[4.2]
  class Spree::Adjustment < ActiveRecord::Base
    belongs_to :adjustable, polymorphic: true
    belongs_to :order, class_name: "Spree::Order"
  end

  class Spree::LineItem < ActiveRecord::Base
    belongs_to :order, class_name: "Spree::Order"
  end

  def up
    add_column :spree_adjustments, :order_id, :integer

    # Ensure migration can use the new column
    Spree::Adjustment.reset_column_information

    # Migrate adjustments on orders
    Spree::Adjustment.where(order_id: nil, adjustable_type: "Spree::Order").find_each do |adjustment|
      adjustment.update_column(:order_id, adjustment.adjustable_id)
    end

    # Migrate adjustments on line_items
    Spree::Adjustment.where(order_id: nil, adjustable_type: "Spree::LineItem").includes(:adjustable).find_each do |adjustment|
      line_item = adjustment.adjustable

      # In some cases a line item has been deleted but an orphaned adjustment remains in the
      # database. There is no way for this orphan to ever be returned or accessed via any scopes,
      # and no way to know what order it related to. In this case we can remove the record.
      if line_item.nil?
        adjustment.delete
        next
      end

      adjustment.update_column(:order_id, line_item.order_id)
    end
  end

  def down
    remove_column :spree_adjustments, :order_id
  end
end
