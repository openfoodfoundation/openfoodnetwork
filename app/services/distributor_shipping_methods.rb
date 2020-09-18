# frozen_string_literal: true

class DistributorShippingMethods
  def self.shipping_methods(distributor, checkout = false, customer = nil)
    methods = if checkout
                distributor.shipping_methods.display_on_checkout.to_a
              else
                distributor.shipping_methods.to_a
              end

    OpenFoodNetwork::TagRuleApplicator.new(
      distributor, "FilterShippingMethods", customer.andand.tag_list
    ).filter!(methods)

    methods.uniq
  end
end
