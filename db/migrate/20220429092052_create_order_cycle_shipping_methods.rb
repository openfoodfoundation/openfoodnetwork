class CreateOrderCycleShippingMethods < ActiveRecord::Migration[6.1]
  # Before this migration every available shipping method was available to customers on order
  # cycles by default. However this migration only populates :order_cycles_shipping_methods records
  # for active or upcoming order cycles because retroactively calculating which shipping methods
  # should be attached to past, closed order cycles is probaby tricky so skipping that because it
  # may not be even necessary. Instead this adds a :shipping_methods_customisable flag to order
  # cycles so we have a record of order cycles created before this feature was deployed.
  #
  # Note: Redefining the Spree::ShippingMethod class in this migration as suggested by the
  # :good_migrations gem was not passing Good Migrations checks. This redefines the classes inside
  # a Migration class to to bypass this problem.

  class Migration
    class DistributorShippingMethod < ActiveRecord::Base
      self.table_name = "distributors_shipping_methods"
      belongs_to :shipping_method, class_name: "Migration::ShippingMethod", touch: true
      belongs_to :distributor, class_name: "Enterprise", touch: true
    end

    class Enterprise < ActiveRecord::Base
    end

    class Exchange < ActiveRecord::Base
      self.table_name = "exchanges"
      belongs_to :receiver, class_name: 'Migration::Enterprise'
    end

    class OrderCycle < ActiveRecord::Base
      self.table_name = "order_cycles"
      has_many :order_cycle_shipping_methods, class_name: "Migration::OrderCycleShippingMethod"
      has_many :shipping_methods, class_name: "Migration::ShippingMethod", through: :order_cycle_shipping_methods

      has_many :cached_outgoing_exchanges, -> { where incoming: false }, class_name: "Migration::Exchange"
      has_many :distributors, -> { distinct }, source: :receiver, through: :cached_outgoing_exchanges

      belongs_to :coordinator, class_name: 'Migration::Enterprise'

      scope :active, lambda {
        where('order_cycles.orders_open_at <= ? AND order_cycles.orders_close_at >= ?',
              Time.zone.now,
              Time.zone.now)
      }
      scope :upcoming, lambda { where('order_cycles.orders_open_at > ?', Time.zone.now) }
    end

    class OrderCycleShippingMethod < ActiveRecord::Base
      self.table_name = "order_cycle_shipping_methods"
      belongs_to :shipping_method, class_name: "Migration::ShippingMethod"
    end

    class ShippingMethod < ActiveRecord::Base
      self.table_name = "spree_shipping_methods"
    end

    def self.attach_all_shipping_methods_to_non_simple_active_or_upcoming_order_cycles
      non_simple_active_or_upcoming_order_cycles.find_each do |order_cycle|
        order_cycle.shipping_method_ids = DistributorShippingMethod.
          where("display_on != 'back_end'").
          where(distributor_id: order_cycle.distributor_ids).
          joins(:shipping_method).
          pluck(:shipping_method_id)
      end
    end

    def self.set_shipping_methods_customisable_to_false_on_past_order_cycles
      OrderCycle.update_all(shipping_methods_customisable: false)
      active_or_upcoming_order_cycles.update_all(shipping_methods_customisable: true)
    end

    private

    def self.active_or_upcoming_order_cycles
      OrderCycle.active.or(OrderCycle.upcoming)
    end

    def self.non_simple_active_or_upcoming_order_cycles
      active_or_upcoming_order_cycles.joins(:coordinator).where("sells != 'own'")
    end
  end

  def up
    create_table :order_cycle_shipping_methods do |t|
      t.references :order_cycle
      t.references :shipping_method, foreign_key: { to_table: :spree_shipping_methods }
      t.timestamps
    end

    add_column :order_cycles, :shipping_methods_customisable, :boolean, default: true

    Migration.set_shipping_methods_customisable_to_false_on_past_order_cycles
    Migration.attach_all_shipping_methods_to_non_simple_active_or_upcoming_order_cycles
  end

  def down
    remove_column :order_cycles, :shipping_methods_customisable
    drop_table :order_cycle_shipping_methods
  end
end
