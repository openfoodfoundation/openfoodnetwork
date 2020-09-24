# frozen_string_literal: true

class DistributorShippingMethods
  def self.shipping_methods(distributor:, checkout: false, apply_tags: true, customer: nil)
    return [] if distributor.blank?

    shipping_methods = distributor.shipping_methods
    shipping_methods = shipping_methods.display_on_checkout if checkout
    shipping_methods = shipping_methods.to_a

    if apply_tags
      OpenFoodNetwork::TagRuleApplicator.new(
        distributor, "FilterShippingMethods", customer&.tag_list
      ).filter!(shipping_methods)
    end

    shipping_methods.uniq
  end
end
