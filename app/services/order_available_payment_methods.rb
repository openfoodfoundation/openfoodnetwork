# frozen_string_literal: true

class OrderAvailablePaymentMethods
  attr_reader :order, :customer

  delegate :distributor,
           :order_cycle,
           to: :order

  def initialize(order, customer = nil)
    @order, @customer = order, customer
  end

  def to_a
    return [] if distributor.blank?

    payment_methods = payment_methods_before_tag_rules_applied

    applicator = OpenFoodNetwork::TagRuleApplicator.new(distributor,
                                                        "FilterPaymentMethods", customer&.tag_list)
    applicator.filter!(payment_methods)

    payment_methods.uniq
  end

  private

  def payment_methods_before_tag_rules_applied
    if order_cycle.nil? || order_cycle.simple?
      distributor.payment_methods
    else
      distributor.payment_methods.where(
        id: order_cycle.distributor_payment_methods.select(:payment_method_id)
      )
    end.available.select(&:configured?)
  end
end
