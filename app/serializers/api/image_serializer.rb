# frozen_string_literal: true

class Api::ImageSerializer < ActiveModel::Serializer
  attributes :id, :alt, :thumb_url, :small_url, :image_url, :large_url

  def thumb_url
    object.url(:mini)
  end

  def small_url
    object.url(:small)
  end

  def image_url
    object.url(:product)
  end

  def large_url
    object.url(:large)
  end
end
