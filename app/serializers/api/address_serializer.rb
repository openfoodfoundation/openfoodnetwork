class Api::AddressSerializer < ActiveModel::Serializer
  attributes :id, :zipcode, :city, :state 

  def state
    object.state.abbr
  end
end
