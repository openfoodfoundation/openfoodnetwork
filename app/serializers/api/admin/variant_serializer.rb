class Api::Admin::VariantSerializer < ActiveModel::Serializer
  attributes :id, :options_text, :unit_value, :unit_description, :unit_to_display, :on_demand, :display_as, :display_name, :name_to_display, :sku
  attributes :on_hand, :price
  has_many :variant_overrides

  def on_hand
    object.on_hand.nil? ? 0 : ( object.on_hand.to_f.finite? ? object.on_hand : I18n.t(:on_demand) )
  end

  def price
    # Decimals are passed to json as strings, we need to run parseFloat.toFixed(2) on the client side.
    object.price.nil? ? 0.to_f : object.price
  end
end
