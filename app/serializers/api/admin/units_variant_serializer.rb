class Api::Admin::UnitsVariantSerializer < ActiveModel::Serializer
  attributes :id, :unit_text, :unit_value

  def unit_text
    options_text = object.options_text
    object.product.name + (options_text.empty? ? "" : ": #{options_text}")
  end
end
