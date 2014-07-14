require 'spec_helper'

describe CheckoutController do
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

  it "doesn't copy the previous shipping address from a pickup order" do
    old_order = create(:order, bill_address: create(:address), ship_address: create(:address))
    Spree::Order.stub_chain(:order, :where, :where, :limit, :detect).and_return(old_order)
    controller.send(:find_last_used_addresses, "email").last.should == nil 
  end

  describe "building the order" do
    before do
      controller.stub(:current_distributor).and_return(distributor)
      controller.stub(:current_order_cycle).and_return(order_cycle)
      controller.stub(:current_order).and_return(order)
    end

    it "does not clone the ship address from distributor when shipping method requires address" do
      get :edit
      assigns[:order].ship_address.address1.should be_nil
    end
    
    it "clears the ship address when re-rendering edit" do
      controller.should_receive(:clear_ship_address).and_return true
      order.stub(:update_attributes).and_return false
      spree_post :update, order: {}
    end

    it "clears the ship address when the order state cannot be advanced" do
      controller.should_receive(:clear_ship_address).and_return true
      order.stub(:update_attributes).and_return true
      order.stub(:next).and_return false
      spree_post :update, order: {}
    end

    it "only clears the ship address with a pickup shipping method" do
      order.stub_chain(:shipping_method, :andand, :require_ship_address).and_return false
      order.should_receive(:ship_address=)
      controller.send(:clear_ship_address)
    end
  end

  context "via xhr" do
    before do
      controller.stub(:current_distributor).and_return(distributor)

      controller.stub(:current_order_cycle).and_return(order_cycle)
      controller.stub(:current_order).and_return(order)
    end

    it "returns errors" do
      xhr :post, :update, order: {}, use_route: :spree
      response.status.should == 400
      response.body.should == {errors: assigns[:order].errors, flash: {}}.to_json
    end

    it "returns flash" do
      order.stub(:update_attributes).and_return true
      order.stub(:next).and_return false
      xhr :post, :update, order: {}, use_route: :spree
      response.body.should == {errors: assigns[:order].errors, flash: {error: "Payment could not be processed, please check the details you entered"}}.to_json
    end

    it "returns order confirmation url on success" do
      order.stub(:update_attributes).and_return true
      order.stub(:state).and_return "complete"

      xhr :post, :update, order: {}, use_route: :spree
      response.status.should == 200
      response.body.should == {path: spree.order_path(order)}.to_json
    end
  end

  describe "Paypal routing" do
    let(:payment_method) { create(:payment_method, type: "Spree::BillingIntegration::PaypalExpress") }
    before do
      controller.stub(:current_distributor).and_return(distributor)
      controller.stub(:current_order_cycle).and_return(order_cycle)
      controller.stub(:current_order).and_return(order)
    end

    it "should check the payment method for Paypalness if we've selected one" do
      Spree::PaymentMethod.should_receive(:find).with(payment_method.id.to_s).and_return payment_method
      order.stub(:update_attributes).and_return true
      order.stub(:state).and_return "payment"
      spree_post :update, order: {payments_attributes: [{payment_method_id: payment_method.id}]}
    end

    it "should override the cancel return url" do
      controller.stub(:params).and_return({payment_method_id: payment_method.id})
      controller.send(:order_opts, order, payment_method.id, 'payment')[:cancel_return_url].should == checkout_url
    end
  end
end
