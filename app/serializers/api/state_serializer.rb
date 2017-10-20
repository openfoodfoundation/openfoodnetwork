class Api::StateSerializer < ActiveModel::Serializer
  attributes :id, :name, :abbr, :display_name

  def display_name
    object.display_name
  end

  def abbr
    object.abbr.upcase
  end
end
