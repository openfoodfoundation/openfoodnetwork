class Api::Admin::UnitsProductSerializer < ActiveModel::Serializer
  attributes :id, :name, :group_buy_unit_size, :variant_unit
end
