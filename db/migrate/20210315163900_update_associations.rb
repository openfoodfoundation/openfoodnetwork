class UpdateAssociations < ActiveRecord::Migration[5.0]
  class Spree::Adjustment < ActiveRecord::Base
    belongs_to :adjustable, polymorphic: true
    belongs_to :order, class_name: "Spree::Order"
  end

  def up
    # Updates any adjustments missing an order association
    Spree::Adjustment.
      where(order_id: nil, adjustable_type: "Spree::Order").
      update_all("order_id = adjustable_id")
  end
end
