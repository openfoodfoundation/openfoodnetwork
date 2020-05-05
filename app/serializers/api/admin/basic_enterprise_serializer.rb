class Api::Admin::BasicEnterpriseSerializer < ActiveModel::Serializer
  attributes :name, :id, :is_primary_producer, :is_distributor, :sells, :category,
             :payment_method_ids, :shipping_method_ids, :producer_profile_only, :permalink

  def payment_method_ids
    object.payment_methods.map(&:id)
  end

  def shipping_method_ids
    object.shipping_methods.map(&:id)
  end
end
