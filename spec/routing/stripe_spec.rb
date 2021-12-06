# frozen_string_literal: true

require "spec_helper"

describe "routing for Stripe return URLS", type: :routing do
  before do
    allow_any_instance_of(SplitCheckoutConstraint).to receive(:current_user) { build(:user) }
  end

  it "routes /checkout to checkout#edit" do
    expect(get: "checkout").
      to route_to("checkout#edit")
  end

  it "routes /checkout?test=123 to checkout#edit" do
    expect(get: "/checkout?test=123").
      to route_to(controller: "checkout", action: "edit", test: "123")
  end

  it "routes /checkout?payment_intent=pm_123 to payment_gateways/stripe#confirm" do
    expect(get: "/checkout?payment_intent=pm_123").
      to route_to(controller: "payment_gateways/stripe", action: "confirm", payment_intent: "pm_123")
  end
end
