class MigratePaymentFeesToPayments < ActiveRecord::Migration[4.2]
  class Spree::Adjustment < ActiveRecord::Base
    belongs_to :originator, polymorphic: true
  end

  def up
    # Payment fee adjustments currently have the order as the `adjustable` and the payment as
    # the `source`. Both `source` and `adjustable` will now be the payment. The `originator` is
    # the payment method, and this is unchanged.
    Spree::Adjustment.where(originator_type: 'Spree::PaymentMethod').update_all(
      "adjustable_id = source_id, adjustable_type = 'Spree::Payment'"
    )
  end

  def down
    # Just in case: reversing this migration requires setting the `adjustable` back to the order.
    # The type is 'Spree::Order', and the order's id is still available on the `order_id` field.
    Spree::Adjustment.where(originator_type: 'Spree::PaymentMethod').update_all(
      "adjustable_id = order_id, adjustable_type = 'Spree::Order'"
    )
  end
end
