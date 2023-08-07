# frozen_string_literal: true

require "open_food_network/scope_variant_to_hub"

class Api::ProductSerializer < ActiveModel::Serializer
  attributes :id, :name, :meta_keywords
  attributes :group_buy, :notes, :description, :description_html
  attributes :properties_with_values

  has_many :variants, serializer: Api::VariantSerializer

  has_one :primary_taxon, serializer: Api::TaxonSerializer

  has_one :image, serializer: Api::ImageSerializer
  has_one :supplier, serializer: Api::IdSerializer

  # return an unformatted descripton
  def description
    sanitizer.strip_content(object.description)
  end

  # return a sanitized html description
  def description_html
    sanitizer.sanitize_content(object.description)&.html_safe
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
end
