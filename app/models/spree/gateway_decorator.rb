Spree::Gateway.class_eval do
  # Default to live
  preference :server, :string, :default => 'live'
  preference :test_mode, :boolean, :default => false

  attr_accessible :distributor_ids
  has_and_belongs_to_many :distributors, join_table: 'distributors_payment_methods', :class_name => 'Enterprise', foreign_key: 'payment_method_id', association_foreign_key: 'distributor_id'
end
