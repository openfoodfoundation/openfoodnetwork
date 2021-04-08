# frozen_string_literal: true

FactoryBot.define do
  factory :filter_order_cycles_tag_rule, class: TagRule::FilterOrderCycles do
    enterprise factory: :distributor_enterprise
  end

  factory :filter_shipping_methods_tag_rule, class: TagRule::FilterShippingMethods do
    enterprise factory: :distributor_enterprise
  end

  factory :filter_products_tag_rule, class: TagRule::FilterProducts do
    enterprise factory: :distributor_enterprise
  end

  factory :filter_payment_methods_tag_rule, class: TagRule::FilterPaymentMethods do
    enterprise factory: :distributor_enterprise
  end
end
