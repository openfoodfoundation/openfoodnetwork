class MigrateLineItemFees < ActiveRecord::Migration[4.2]
  class Spree::Adjustment < ActiveRecord::Base
    belongs_to :originator, polymorphic: true
    belongs_to :source, polymorphic: true
  end

  def up
    Spree::Adjustment.
      where(originator_type: 'EnterpriseFee', source_type: 'Spree::LineItem').
      update_all(
        "adjustable_id = source_id, adjustable_type = 'Spree::LineItem'"
      )
  end

  def down
    Spree::Adjustment.
      where(originator_type: 'EnterpriseFee', source_type: 'Spree::LineItem').
      update_all(
        "adjustable_id = order_id, adjustable_type = 'Spree::Order'"
      )
  end
end
