class Api::TaxonImageSerializer < ActiveModel::Serializer
  attributes :id, :alt, :small_url, :large_url

  def small_url
    object.attachment.url(:small, false)
  end

  def large_url
    object.attachment.url(:large, false)
  end
end
