class Api::Admin::LineItemSerializer < ActiveModel::Serializer
  attributes :id, :quantity, :max_quantity, :supplier, :price, :unit_value, :units_product, :units_variant

  def supplier
    Api::Admin::IdNameSerializer.new(object.product.supplier).serializable_hash
  end

  def units_product
    Api::Admin::UnitsProductSerializer.new(object.product).serializable_hash
  end

  def units_variant
    Api::Admin::UnitsVariantSerializer.new(object.variant).serializable_hash
  end

  def unit_value
    object.unit_value.to_f
  end
end
