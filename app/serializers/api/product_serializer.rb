# frozen_string_literal: true

require "open_food_network/scope_variant_to_hub"

class Api::ProductSerializer < ActiveModel::Serializer
  attributes :id, :name, :meta_keywords
  attributes :group_buy, :notes, :description, :description_html
  attributes :properties_with_values
  # The id and name of the product as its page's URL names it.
  attributes :to_param

  has_many :variants, serializer: Api::VariantSerializer

  has_one :image, serializer: Api::ImageSerializer

  # The serializer has a #to_param of its own.
  delegate :to_param, to: :object

  # return an unformatted descripton
  def description
    sanitizer.strip_content(object.description)
  end

  # return a sanitized html description
  def description_html
    trix_sanitizer.sanitize_content(object.description)
  end

  def properties_with_values
    object.properties_including_inherited
  end

  def variants
    options[:variants][object.id] || []
  end

  private

  def sanitizer
    @sanitizer ||= ContentSanitizer.new
  end

  def trix_sanitizer
    @trix_sanitizer ||= TrixSanitizer.new
  end
end
