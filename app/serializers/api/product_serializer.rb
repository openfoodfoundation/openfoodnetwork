require "open_food_network/scope_variant_to_hub"

class Api::ProductSerializer < ActiveModel::Serializer
  include ActionView::Helpers::SanitizeHelper

  attributes :id, :name, :permalink, :meta_keywords
  attributes :group_buy, :notes, :description, :description_html
  attributes :properties_with_values, :price

  has_many :variants, serializer: Api::VariantSerializer
  has_one :master, serializer: Api::VariantSerializer

  has_one :primary_taxon, serializer: Api::TaxonSerializer
  has_many :taxons, serializer: Api::IdSerializer

  has_many :images, serializer: Api::ImageSerializer
  has_one :supplier, serializer: Api::IdSerializer

  # return an unformatted descripton
  def description
    strip_tags object.description&.strip
  end

  # return a sanitized html description
  def description_html
    d = sanitize(object.description, tags: ["p", "b", "strong", "em", "i", "a", "u"],
                                     attributes: ["href", "target"])
    d.to_s.html_safe
  end

  def properties_with_values
    object.properties_including_inherited
  end

  def variants
    options[:variants][object.id] || []
  end

  def master
    options[:master_variants][object.id].andand.first
  end

  def price
    if options[:enterprise_fee_calculator]
      object.master.price + options[:enterprise_fee_calculator].indexed_fees_for(object.master)
    else
      object.master.price_with_fees(options[:current_distributor], options[:current_order_cycle])
    end
  end
end
