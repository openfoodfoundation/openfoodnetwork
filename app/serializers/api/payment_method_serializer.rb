# frozen_string_literal: true

class Api::PaymentMethodSerializer < ActiveModel::Serializer
  attributes :name, :description, :id, :method_type,
             :price

  def price
    object.compute_amount(options[:current_order])
  end
end
