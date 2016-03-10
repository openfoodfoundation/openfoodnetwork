class Api::Admin::EnterpriseSerializer < ActiveModel::Serializer
  attributes :name, :id, :is_primary_producer, :is_distributor, :sells, :category, :payment_method_ids, :shipping_method_ids
  attributes :producer_profile_only, :email, :long_description, :permalink
  attributes :preferred_shopfront_message, :preferred_shopfront_closed_message, :preferred_shopfront_taxon_order, :preferred_shopfront_order_cycle_order
  attributes :preferred_product_selection_from_inventory_only
  attributes :owner, :users

  has_one :owner, serializer: Api::Admin::UserSerializer
  has_many :users, serializer: Api::Admin::UserSerializer
  has_many :tag_rules, serializer: Api::Admin::TagRuleSerializer
end
