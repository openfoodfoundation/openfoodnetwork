require 'spec_helper'

describe Shop::CheckoutController do
  let(:distributor) { double(:distributor) }
  let(:order_cycle) { create(:order_cycle) }
  let(:order) { create(:order) }
  before do
    order.stub(:checkout_allowed?).and_return true
    controller.stub(:check_authorization).and_return true
  end
  it "redirects home when no distributor is selected" do
    get :edit
    response.should redirect_to root_path
  end

  it "redirects to the shop when no order cycle is selected" do
    controller.stub(:current_distributor).and_return(distributor)
    get :edit
    response.should redirect_to shop_path
  end

  it "redirects to the shop when no line items are present" do
    controller.stub(:current_distributor).and_return(distributor)
    controller.stub(:current_order_cycle).and_return(order_cycle)
    controller.stub(:current_order).and_return(order)
    order.stub_chain(:insufficient_stock_lines, :present?).and_return true
    get :edit
    response.should redirect_to shop_path
  end

  it "renders when both distributor and order cycle is selected" do
    controller.stub(:current_distributor).and_return(distributor)
    controller.stub(:current_order_cycle).and_return(order_cycle)
    controller.stub(:current_order).and_return(order)
    order.stub_chain(:insufficient_stock_lines, :present?).and_return false
    get :edit
    response.should be_success
  end

  describe "building the order" do
    before do
      controller.stub(:current_distributor).and_return(distributor)
      controller.stub(:current_order_cycle).and_return(order_cycle)
      controller.stub(:current_order).and_return(order)
    end
    it "does not clone the ship address from distributor" do
      get :edit
      assigns[:order].ship_address.address1.should be_nil
    end
  end

  describe "Paypal routing" do
    let(:payment_method) { create(:payment_method) }
    before do
      controller.stub(:current_distributor).and_return(distributor)
      controller.stub(:current_order_cycle).and_return(order_cycle)
      controller.stub(:current_order).and_return(order)
    end

    it "should check the payment method for Paypalness if we've selected one" do
      Spree::PaymentMethod.should_receive(:find).with(payment_method.id.to_s).and_return payment_method
      spree_post :update, order: {payments_attributes: [{payment_method_id: payment_method.id}]}
    end
  end
end
