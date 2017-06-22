class Api::Admin::Reports::ProductSerializer < ActiveModel::Serializer
  attributes :id, :name, :group_buy_unit_size

  has_one :supplier, key: :producer, serializer: Api::Admin::IdNameSerializer

  def group_buy_unit_size
    object.group_buy_unit_size.to_f
  end
end
