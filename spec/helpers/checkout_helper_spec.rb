# frozen_string_literal: true

require 'spec_helper'

describe CheckoutHelper, type: :helper do
  it "generates html for validated inputs" do
    expect(helper).to receive(:render).with(
      "shared/validated_input",
      name: "test",
      path: "foo",
      attributes: { :required => true, :type => :email, :name => "foo", :id => "foo", "ng-model" => "foo", "ng-class" => "{error: !fieldValid('foo')}" }
    )

    helper.validated_input("test", "foo", type: :email)
  end

  describe "displaying the tax total for an order" do
    let(:order) { double(:order, total_tax: 123.45, currency: 'AUD') }

    it "retrieves the total tax on the order" do
      expect(helper.display_checkout_tax_total(order)).to eq(Spree::Money.new(123.45, currency: 'AUD'))
    end
  end

  it "knows if guests can checkout" do
    distributor = create(:distributor_enterprise)
    order = create(:order, distributor: distributor)
    allow(helper).to receive(:current_order) { order }
    expect(helper.guest_checkout_allowed?).to be true

    order.distributor.allow_guest_orders = false
    expect(helper.guest_checkout_allowed?).to be false
  end
end
