# frozen_string_literal: true

class Api::AddressSerializer < ActiveModel::Serializer
  # cached
  # delegate :cache_key, to: :object

  attributes :id, :zipcode, :city, :state_name, :state_id,
             :phone, :firstname, :lastname, :address1, :address2, :city, :country_id,
             :zipcode, :country_name

  def country_name
    object.country&.name
  end

  def state_name
    object.state&.abbr
  end
end
