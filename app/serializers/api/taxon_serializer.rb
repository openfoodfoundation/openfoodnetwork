class Api::TaxonSerializer < ActiveModel::Serializer
  cached
  delegate :cache_key, to: :object

  attributes :id, :name, :permalink, :icon, :pretty_name, :position, :parent_id, :taxonomy_id

  def icon
    object.icon(:original)
  end
end
