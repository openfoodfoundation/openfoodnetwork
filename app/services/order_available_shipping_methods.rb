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

    tag_rules.filter(shipping_methods)
  end

  private

  def shipping_methods
    if order_cycle.nil? || order_cycle.simple?
      distributor.shipping_methods
    else
      distributor.shipping_methods.where(
        id: available_distributor_shipping_methods_ids
      )
    end.frontend.to_a.uniq
  end

  def available_distributor_shipping_methods_ids
    order_cycle.distributor_shipping_methods
      .where(distributor_id: distributor.id)
      .select(:shipping_method_id)
  end

  def tag_rules
    OpenFoodNetwork::TagRuleApplicator.new(
      distributor, "FilterShippingMethods", customer&.tag_list
    )
  end
end
