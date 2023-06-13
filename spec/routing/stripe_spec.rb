# frozen_string_literal: true

require "spec_helper"

describe "routing for Stripe return URLS", type: :routing do
  context "checkout return URLs" do
    it "routes /checkout to checkout#edit" do
      expect(get: "checkout").
        to route_to("split_checkout#edit")
    end

    it "routes /checkout?test=123 to checkout#edit" do
      expect(get: "/checkout?test=123").
        to route_to(controller: "split_checkout", action: "edit", test: "123")
    end

    it "routes /checkout?payment_intent=pm_123 to payment_gateways/stripe#confirm" do
      expect(get: "/checkout?payment_intent=pm_123").
        to route_to(controller: "payment_gateways/stripe",
                    action: "confirm", payment_intent: "pm_123")
    end
  end

  context "authorization return URLs" do
    let(:order) { create(:order) }

    it "routes /orders/:number to spree/orders#show" do
      expect(get: "orders/#{order.number}").
        to route_to(controller: "spree/orders", action: "show", id: order.number)
    end

    it "routes /orders/:number?test=123 to spree/orders#show" do
      expect(get: "/orders/#{order.number}?test=123").
        to route_to(controller: "spree/orders", action: "show", id: order.number, test: "123")
    end

    it "routes /orders/:number?payment_intent=pm_123 to payment_gateways/stripe#authorize" do
      expect(get: "/orders/#{order.number}?payment_intent=pm_123").
        to route_to(controller: "payment_gateways/stripe", action: "authorize",
                    order_number: order.number, payment_intent: "pm_123")
    end
  end
end
