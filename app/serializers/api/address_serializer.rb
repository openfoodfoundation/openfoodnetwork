class Api::AddressSerializer < ActiveModel::Serializer
  cached
  delegate :cache_key, to: :object

  attributes :id, :zipcode, :city, :state 

  def state
    object.state.abbr
  end
end
