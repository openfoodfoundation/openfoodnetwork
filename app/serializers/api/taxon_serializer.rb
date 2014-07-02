class Api::TaxonSerializer < ActiveModel::Serializer
  attributes :id, :name, :permalink, :icon

  def icon
    object.icon(:original)
  end
end
