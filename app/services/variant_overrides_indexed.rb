# frozen_string_literal: true

class VariantOverridesIndexed
  def initialize(variant_ids, distributor_ids)
    @variant_ids = variant_ids
    @distributor_ids = distributor_ids
  end

  def indexed
    variant_overrides.each_with_object(hash_of_hashes) do |variant_override, indexed|
      indexed[variant_override.hub_id][variant_override.variant] = variant_override
    end
  end

  private

  attr_reader :variant_ids, :distributor_ids

  def variant_overrides
    VariantOverride
      .joins(:variant)
      .preload(:variant)
      .where(
        hub_id: distributor_ids,
        variant_id: variant_ids,
      )
  end

  def hash_of_hashes
    Hash.new { |h, k| h[k] = {} }
  end
end
