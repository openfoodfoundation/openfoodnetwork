Spree::Gateway.class_eval do

  # Due to class load order, when config.cache_classes is enabled (ie. staging and production
  # environments), this association isn't inherited from PaymentMethod. As a result, creating
  # payment methods using payment gateways results in:
  # undefined method `association_class' for nil:NilClass
  # To avoid that, we redefine this association here.

  has_and_belongs_to_many :distributors, join_table: 'distributors_payment_methods', :class_name => 'Enterprise', foreign_key: 'payment_method_id', association_foreign_key: 'distributor_id'


  # Default to live
  preference :server, :string, :default => 'live'
  preference :test_mode, :boolean, :default => false
end
