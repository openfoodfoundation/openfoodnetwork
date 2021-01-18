class AddOrderToAdjustments < ActiveRecord::Migration
  def up
    class Spree::Adjustment < ActiveRecord::Base
      belongs_to :adjustable, polymorphic: true
      belongs_to :order, class_name: "Spree::Order"
    end
    class Spree::LineItem < ActiveRecord::Base
      belongs_to :order, class_name: "Spree::Order"
    end

    add_column :spree_adjustments, :order_id, :integer

    # Ensure migration can use the new column
    Spree::Adjustment.reset_column_information

    # Migrate adjustments on orders
    Spree::Adjustment.where(order_id: nil, adjustable_type: "Spree::Order").find_each do |adjustment|
      adjustment.update_column(:order_id, adjustment.adjustable_id)
    end

    # Migrate adjustments on line_items
    Spree::Adjustment.where(order_id: nil, adjustable_type: "Spree::LineItem").includes(:adjustable).find_each do |adjustment|
      adjustment.update_column(:order_id, adjustment.adjustable.order_id)
    end
  end
end
