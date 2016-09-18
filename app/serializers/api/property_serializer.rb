class Api::PropertySerializer < ActiveModel::Serializer
  attributes :id, :name, :presentation
end
