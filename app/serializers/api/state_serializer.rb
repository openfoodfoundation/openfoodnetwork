class Api::StateSerializer < ActiveModel::Serializer
  attributes :id, :name, :abbr

  def abbr
    object.abbr.upcase
  end
end
