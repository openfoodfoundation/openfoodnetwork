class Api::Admin::VariantSerializer < ActiveModel::Serializer
  attributes :id, :options_text, :unit_value, :unit_description, :unit_to_display, :on_demand, :display_as, :display_name, :name_to_display, :sku
  attributes :on_hand, :price, :import_date, :name, :producer_name, :image
  has_many :variant_overrides

  def name
    if object.full_name.present?
      "#{object.name} - #{object.full_name}"
    else
      object.name
    end
  end

  def on_hand
    return 0 if object.on_hand.nil?
    object.on_hand
  end

  def price
    # Decimals are passed to json as strings, we need to run parseFloat.toFixed(2) on the client side.
    object.price.nil? ? 0.to_f : object.price
  end

  def producer_name
    object.product.supplier.name
  end

  def image
    object.product.images.first.mini_url
  end
end
