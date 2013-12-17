module Spree

  class ImageSerializer < ActiveModel::Serializer
    attributes :id, :mini_url, :alt
  end
end
