class ConvertShippingMethodsDistributorsToHabtm < ActiveRecord::Migration
  class Spree::ShippingMethod < ActiveRecord::Base
    belongs_to :distributor, class_name: 'Enterprise'
    has_and_belongs_to_many :distributors, join_table: 'distributors_shipping_methods', :class_name => 'Enterprise', association_foreign_key: 'distributor_id'
  end

  def up
    create_table :distributors_shipping_methods, id: false do |t|
      t.references :distributor
      t.references :shipping_method
    end
    add_index :distributors_shipping_methods, :distributor_id
    add_index :distributors_shipping_methods, :shipping_method_id

    Spree::ShippingMethod.all.each do |sm|
      sm.distributors << sm.distributor if sm.distributor_id
    end

    remove_column :spree_shipping_methods, :distributor_id
  end

  def down
    add_column :spree_shipping_methods, :distributor_id, :integer
    add_index :spree_shipping_methods, :distributor_id

    Spree::ShippingMethod.all.each do |sm|
      if sm.distributors.present?
        sm.distributor = sm.distributors.first
        sm.save!

        say "WARNING: Discarding #{sm.distributors.count-1} distributors while flattening HABTM relation to belongs_to" if sm.distributors.count > 1
      end
    end

    drop_table :distributors_shipping_methods
  end
end
