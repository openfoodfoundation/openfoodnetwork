class CreateDistributorsPaymentMethods < ActiveRecord::Migration
  class Spree::PaymentMethod < ActiveRecord::Base
    belongs_to :distributor, class_name: 'Enterprise'
    has_and_belongs_to_many :distributors, join_table: 'distributors_payment_methods', :class_name => 'Enterprise', association_foreign_key: 'distributor_id'
  end

  def up
    create_table :distributors_payment_methods, :id => false do |t|
      t.references :distributor
      t.references :payment_method
    end
    Spree::PaymentMethod.all.each do |pm|
      pm.distributors << pm.distributor if pm.distributor_id
    end
  end

  def down
    drop_table :distributors_payment_methods
  end
end
