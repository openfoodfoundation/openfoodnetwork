# frozen_string_literal: true

# This represent a read only Product value object, to be used in the view.
# `:variants` is an array of ViewData::Variant, already filtered for the shop.
#
# NOTE: Data instances are frozen, so these readers can't memoise. They only fold over the
# handful of variants a product has, which is cheap enough to repeat.
ViewData::Product = Data.define(:id, :name, :description, :image, :images, :variant_images,
                                :properties_including_inherited, :variants) do
  def single_variant?
    variants.one?
  end

  # The only variant, or nil when the product has several (or none).
  def variant
    variants.first if single_variant?
  end

  # Producer of each variant, following linked variants back to their source. This is not the
  # same as the variants' own enterprise, which for a linked variant is the reselling hub.
  def producers
    variants.map(&:producer).uniq
  end

  def single_producer?
    producers.one?
  end

  # Fees vary per variant, so the cheapest to buy is not necessarily the cheapest listed.
  def cheapest_variant
    variants.min_by(&:price_with_fees)
  end
end
