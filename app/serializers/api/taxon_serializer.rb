class Api::TaxonSerializer < ActiveModel::Serializer
  attributes :id, :name, :permalink
end
