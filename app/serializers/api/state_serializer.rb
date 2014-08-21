class Api::StateSerializer < ActiveModel::Serializer
  attributes :id, :name, :abbr
end