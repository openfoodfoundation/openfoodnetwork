class Api::Admin::ForOrderCycle::EnterpriseSerializer < ActiveModel::Serializer
  attributes :id, :name, :managed, :supplied_products
  attributes :is_primary_producer, :is_distributor, :sells

  def managed
    Enterprise.managed_by(options[:spree_current_user]).include? object
  end

  def supplied_products
    objects = object.supplied_products.not_deleted
    serializer = Api::Admin::ForOrderCycle::SuppliedProductSerializer
    ActiveModel::ArraySerializer.new(objects, each_serializer: serializer)
  end
end
