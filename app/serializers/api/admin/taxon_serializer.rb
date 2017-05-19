class Api::Admin::TaxonSerializer < ActiveModel::Serializer
  attributes :id, :name, :pretty_name
end
