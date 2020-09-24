# frozen_string_literal: true

require 'spec_helper'

describe DistributorShippingMethods do
  let!(:enterprise) { create(:distributor_enterprise) }
  let!(:shipping_method) { create(:shipping_method, distributors: [enterprise]) }
  let!(:member_shipping_method) { create(:shipping_method, distributors: [enterprise]) }
  let!(:backend_shipping_method) { create(:shipping_method, distributors: [enterprise]) }
  let!(:customer) { create(:customer) }
  let!(:sm_tag_rule) {
    create(
      :filter_shipping_methods_tag_rule,
      enterprise: enterprise,
      priority: 2,
      preferred_customer_tags: "member",
      preferred_shipping_method_tags: "member",
      preferred_matched_shipping_methods_visibility: "visible"
    )
  }

  let!(:default_sm_tag_rule) {
    create(
      :filter_shipping_methods_tag_rule,
      enterprise: enterprise,
      priority: 1,
      is_default: true,
      preferred_shipping_method_tags: [],
      preferred_customer_tags: [],
      preferred_matched_shipping_methods_visibility: "hidden"
    )
  }

  it "returns all shipping methods for a distributor" do
    expect(DistributorShippingMethods.shipping_methods(distributor: enterprise).count).to eq(3)
  end

  it "does not return a shipping method tagged as 'member' for a customer without that tag" do
    member_shipping_method.tag_list << "member"
    member_shipping_method.save
    result =
      DistributorShippingMethods.shipping_methods(distributor: enterprise, customer: customer)
    expect(result).to include(shipping_method)
    expect(result).to include(backend_shipping_method)
  end

  it "returns the shipping method tagged 'member' for a customer with that tag" do
    member_customer = create(:customer)
    member_customer.tag_list << "member"
    member_customer.save
    member_shipping_method.tag_list << "member"
    member_shipping_method.save
    result = DistributorShippingMethods.shipping_methods(
      distributor: enterprise, customer: member_customer
    )
    expect(result).to include(member_shipping_method)
  end

  it "does not return a non-checkout shipping method if passed checkout=true" do
    backend_shipping_method.display_on = "back_end"
    backend_shipping_method.save
    result = DistributorShippingMethods.shipping_methods(
      distributor: enterprise, checkout: true, customer: customer
    )
    expect(result).to include(shipping_method)
  end
end
