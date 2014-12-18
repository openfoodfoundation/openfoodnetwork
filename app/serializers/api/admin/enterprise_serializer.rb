class Api::Admin::EnterpriseSerializer < ActiveModel::Serializer
  attributes :name, :id, :is_primary_producer, :is_distributor, :sells, :category, :payment_method_ids, :shipping_method_ids
  attributes :producer_profile_only, :email, :long_description
  attributes :preferred_shopfront_message, :preferred_shopfront_closed_message, :preferred_shopfront_taxon_order
end