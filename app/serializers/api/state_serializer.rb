class Api::StateSerializer < ActiveModel::Serializer
  attributes :id, :name, :abbr, :display_name

  delegate :display_name, to: :object

  def abbr
    object.abbr.upcase
  end
end
