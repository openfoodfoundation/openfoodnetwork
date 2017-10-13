class Api::Admin::BasicEnterpriseSerializer < ActiveModel::Serializer
  attributes :name, :id, :is_primary_producer, :is_distributor, :sells, :category, :payment_method_ids, :shipping_method_ids
  attributes :producer_profile_only, :permalink
end
