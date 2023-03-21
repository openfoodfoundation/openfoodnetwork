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

    filter_by_category(tag_rules.filter(shipping_methods))
  end

  private

  def filter_by_category(methods)
    return methods unless OpenFoodNetwork::FeatureToggle.enabled?(:match_shipping_categories,
                                                                  distributor&.owner)

    required_category_ids = order.products.pluck(:shipping_category_id).to_set
    return methods if required_category_ids.empty?

    methods.select do |method|
      provided_category_ids = method.shipping_categories.pluck(:id).to_set
      required_category_ids.subset?(provided_category_ids)
    end
  end

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
