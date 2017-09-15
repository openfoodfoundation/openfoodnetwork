class Api::AddressSerializer < ActiveModel::Serializer
  #cached
  #delegate :cache_key, to: :object

  attributes :id, :zipcode, :city, :state_text, :state_id,
    :phone, :firstname, :lastname, :address1, :address2, :city, :country_id,
    :zipcode

  def state_id
    object.state_id.andand.to_s
  end

  def country_id
    object.country_id.andand.to_s
  end
end
