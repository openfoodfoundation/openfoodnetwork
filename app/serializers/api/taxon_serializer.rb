# frozen_string_literal: true

class Api::TaxonSerializer < ActiveModel::Serializer
  cached

  def cache_key
    [object.cache_key, I18n.locale].join("/")
  end

  attributes :id, :name, :permalink, :position
end
