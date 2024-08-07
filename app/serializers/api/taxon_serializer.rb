# frozen_string_literal: true

class Api::TaxonSerializer < ActiveModel::Serializer
  cached
  delegate :cache_key, to: :object

  attributes :id, :name, :permalink, :position
end
