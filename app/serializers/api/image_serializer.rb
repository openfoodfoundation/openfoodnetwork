# frozen_string_literal: true

class Api::ImageSerializer < ActiveModel::Serializer
  attributes :id, :alt, :thumb_url, :small_url, :image_url, :large_url

  def thumb_url
    object.attachment.variant(resize: "48x48#")
  end

  def small_url
    object.attachment.variant(resize: "227x227#")
  end

  def image_url
    object.attachment.variant(resize: "240x240>")
  end

  def large_url
    object.attachment.variant(resize: "600x600>")
  end
end
