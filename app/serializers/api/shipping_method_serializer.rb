# frozen_string_literal: true

class Api::ShippingMethodSerializer < ActiveModel::Serializer
  attributes :id, :require_ship_address, :name, :description,
             :price

  def price
    object.compute_amount(options[:current_order])
  end
end
