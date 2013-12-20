module Spree

  class ImageSerializer < ActiveModel::Serializer
    attributes :id, :small_url, :alt

    def small_url
      object.attachment.url(:small, false)
    end
  end
end
