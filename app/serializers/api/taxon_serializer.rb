class Api::TaxonSerializer < ActiveModel::Serializer
  cached
  delegate :cache_key, to: :object

  attributes :id, :name, :permalink, :icon

  def icon
    object.icon(:original)
  end
end
