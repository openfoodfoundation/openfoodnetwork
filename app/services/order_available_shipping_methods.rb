# frozen_string_literal: true

class OrderAvailableShippingMethods
  attr_reader :order, :customer

  delegate :distributor,
           :order_cycle,
           to: :order

  def initialize(order, customer = nil)
    @order, @customer = order, customer
  end

  def to_a
    return [] if distributor.blank?

    shipping_methods = shipping_methods_before_tag_rules_applied

    applicator = OpenFoodNetwork::TagRuleApplicator.new(distributor,
                                                        "FilterShippingMethods", customer&.tag_list)
    applicator.filter!(shipping_methods)

    shipping_methods.uniq
  end

  private

  def shipping_methods_before_tag_rules_applied
    if order_cycle.nil? || order_cycle.simple?
      distributor.shipping_methods
    else
      distributor.shipping_methods.where(
        id: order_cycle.distributor_shipping_methods.select(:shipping_method_id)
      )
    end.frontend.to_a
  end
end
