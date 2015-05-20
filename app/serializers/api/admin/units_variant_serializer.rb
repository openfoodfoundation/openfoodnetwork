class Api::Admin::UnitsVariantSerializer < ActiveModel::Serializer
  attributes :id, :full_name, :unit_value

  def full_name
    full_name = object.full_name
    object.product.name + (full_name.empty? ? "" : ": #{full_name}")
  end
end
