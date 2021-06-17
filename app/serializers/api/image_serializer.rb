# frozen_string_literal: true

class Api::ImageSerializer < ActiveModel::Serializer
  attributes :id, :alt, :thumb_url, :small_url, :image_url, :large_url

  def thumb_url
    object.attachment.url(:mini, false)
  end

  def small_url
    object.attachment.url(:small, false)
  end

  def image_url
    object.attachment.url(:product, false)
  end

  def large_url
    object.attachment.url(:large, false)
  end
end
