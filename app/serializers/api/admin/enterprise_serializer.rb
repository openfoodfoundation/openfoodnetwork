class Api::Admin::EnterpriseSerializer < ActiveModel::Serializer
  attributes :name, :id, :is_primary_producer, :is_distributor, :payment_method_ids, :shipping_method_ids, :long_description
end
