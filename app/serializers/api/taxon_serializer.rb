# frozen_string_literal: true

class Api::TaxonSerializer < ActiveModel::Serializer
  cached
  delegate :cache_key, to: :object

  attributes :id, :name, :permalink, :pretty_name, :position, :parent_id, :taxonomy_id
end
