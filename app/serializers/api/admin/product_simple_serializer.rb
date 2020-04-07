class Api::Admin::ProductSimpleSerializer < ActiveModel::Serializer
  attributes :id, :name

  has_one :supplier, key: :producer_id, embed: :id
  has_many :variants, key: :variants, serializer: Api::Admin::VariantSimpleSerializer

  def on_hand
    return 0 if object.on_hand.nil?

    object.on_hand
  end

  def price
    object.price.nil? ? '0.0' : object.price
  end
end
