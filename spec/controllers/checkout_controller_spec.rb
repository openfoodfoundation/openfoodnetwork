require 'spec_helper'

describe CheckoutController, type: :controller do
  let(:distributor) { double(:distributor) }
  let(:order_cycle) { create(:simple_order_cycle) }
  let(:order) { create(:order) }
  let(:reset_order_service) { double(ResetOrderService) }

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

  it "redirects home with message if hub is not ready for checkout" do
    distributor.stub(:ready_for_checkout?) { false }
    order.stub(distributor: distributor, order_cycle: order_cycle)
    controller.stub(:current_order).and_return(order)

    order.should_receive(:empty!)
    order.should_receive(:set_distribution!).with(nil, nil)

    get :edit

    response.should redirect_to root_url
    flash[:info].should == "The hub you have selected is temporarily closed for orders. Please try again later."
  end

  it "redirects to the cart when some items are out of stock" do
    controller.stub(:current_distributor).and_return(distributor)
    controller.stub(:current_order_cycle).and_return(order_cycle)
    controller.stub(:current_order).and_return(order)
    order.stub_chain(:insufficient_stock_lines, :present?).and_return true
    get :edit
    response.should redirect_to spree.cart_path
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

    it "does not clone the ship address from distributor when shipping method requires address" do
      get :edit
      assigns[:order].ship_address.address1.should be_nil
    end

    it "clears the ship address when re-rendering edit" do
      controller.should_receive(:clear_ship_address).and_return true
      order.stub(:update_attributes).and_return false
      spree_post :update, format: :json, order: {}
    end

    it "clears the ship address when the order state cannot be advanced" do
      controller.should_receive(:clear_ship_address).and_return true
      order.stub(:update_attributes).and_return true
      order.stub(:next).and_return false
      spree_post :update, format: :json, order: {}
    end

    it "only clears the ship address with a pickup shipping method" do
      order.stub_chain(:shipping_method, :andand, :require_ship_address).and_return false
      order.should_receive(:ship_address=)
      controller.send(:clear_ship_address)
    end

    context 'when completing the order' do
      before do
        order.state = 'complete'
        allow(order).to receive(:update_attributes).and_return(true)
        allow(order).to receive(:next).and_return(true)
        allow(order).to receive(:set_distributor!).and_return(true)
      end

      it "sets the new order's token to the same as the old order" do
        order = controller.current_order(true)
        spree_post :update, order: {}
        expect(controller.current_order.token).to eq order.token
      end

      it 'expires the current order' do
        allow(controller).to receive(:expire_current_order)
        put :update, order: {}
        expect(controller).to have_received(:expire_current_order)
      end

      it 'sets the access_token of the session' do
        put :update, order: {}
        expect(session[:access_token]).to eq(controller.current_order.token)
      end
    end
  end

  describe '#expire_current_order' do
    it 'empties the order_id of the session' do
      expect(session).to receive(:[]=).with(:order_id, nil)
      controller.expire_current_order
    end

    it 'resets the @current_order ivar' do
      controller.expire_current_order
      expect(controller.instance_variable_get(:@current_order)).to be_nil
    end
  end

  context "via xhr" do
    before do
      controller.stub(:current_distributor).and_return(distributor)

      controller.stub(:current_order_cycle).and_return(order_cycle)
      controller.stub(:current_order).and_return(order)
    end

    it "returns errors" do
      spree_post :update, format: :json, order: {}
      response.status.should == 400
      response.body.should == {errors: assigns[:order].errors, flash: {}}.to_json
    end

    it "returns flash" do
      order.stub(:update_attributes).and_return true
      order.stub(:next).and_return false
      spree_post :update, format: :json, order: {}
      response.body.should == {errors: assigns[:order].errors, flash: {error: "Payment could not be processed, please check the details you entered"}}.to_json
    end

    it "returns order confirmation url on success" do
      allow(ResetOrderService).to receive(:new).with(controller, order) { reset_order_service }
      expect(reset_order_service).to receive(:call)

      order.stub(:update_attributes).and_return true
      order.stub(:state).and_return "complete"

      spree_post :update, format: :json, order: {}
      response.status.should == 200
      response.body.should == {path: spree.order_path(order)}.to_json
    end

    describe "stale object handling" do
      it "retries when a stale object error is encountered" do
        allow(ResetOrderService).to receive(:new).with(controller, order) { reset_order_service }
        expect(reset_order_service).to receive(:call)

        order.stub(:update_attributes).and_return true
        controller.stub(:state_callback)

        # The first time, raise a StaleObjectError. The second time, succeed.
        order.stub(:next).once.
          and_raise(ActiveRecord::StaleObjectError.new(Spree::Variant.new, 'update'))
        order.stub(:next).once do
          order.update_column :state, 'complete'
          true
        end

        spree_post :update, format: :json, order: {}
        response.status.should == 200
      end

      it "tries a maximum of 3 times before giving up and returning an error" do
        order.stub(:update_attributes).and_return true
        order.stub(:next) { raise ActiveRecord::StaleObjectError.new(Spree::Variant.new, 'update') }

        spree_post :update, format: :json, order: {}
        response.status.should == 400
      end
    end
  end

  describe "Paypal routing" do
    let(:payment_method) { create(:payment_method, type: "Spree::Gateway::PayPalExpress") }
    before do
      allow(controller).to receive(:current_distributor) { distributor }
      allow(controller).to receive(:current_order_cycle) { order_cycle }
      allow(controller).to receive(:current_order) { order }
      allow(controller).to receive(:restart_checkout)
    end

    it "should check the payment method for Paypalness if we've selected one" do
      expect(Spree::PaymentMethod).to receive(:find).with(payment_method.id.to_s) { payment_method }
      allow(order).to receive(:update_attributes) { true }
      allow(order).to receive(:state) { "payment" }
      spree_post :update, order: {payments_attributes: [{payment_method_id: payment_method.id}]}
    end
  end

  describe "#update_failed" do
    before do
      controller.instance_variable_set(:@order, order)
    end

    it "clears the shipping address and restarts the checkout" do
      expect(controller).to receive(:clear_ship_address)
      expect(controller).to receive(:restart_checkout)
      expect(controller).to receive(:respond_to)
      controller.send(:update_failed)
    end
  end

  describe "#restart_checkout" do
    let!(:shipment_pending) { create(:shipment, order: order, state: 'pending') }
    let!(:payment_checkout) { create(:payment, order: order, state: 'checkout') }
    let!(:payment_failed) { create(:payment, order: order, state: 'failed') }

    before do
      order.update_attribute(:shipping_method_id, shipment_pending.shipping_method_id)
      controller.instance_variable_set(:@order, order.reload)
    end

    context "when the order is already in the 'cart' state" do
      it "does nothing" do
        expect(order).to_not receive(:restart_checkout!)
        controller.send(:restart_checkout)
      end
    end

    context "when the order is in a subsequent state" do
      before do
        order.update_attribute(:state, "payment")
      end

      # NOTE: at the time of writing, it was not possible to create a shipment with a state other than
      # 'pending' when the order has not been completed, so this is not a case that requires testing.
      it "resets the order state, and clears incomplete shipments and payments" do
        expect(order).to receive(:restart_checkout!).and_call_original
        expect(order.shipping_method_id).to_not be nil
        expect(order.shipments.count).to be 1
        expect(order.adjustments.shipping.count).to be 1
        expect(order.payments.count).to be 2
        expect(order.adjustments.payment_fee.count).to be 2
        controller.send(:restart_checkout)
        expect(order.reload.state).to eq 'cart'
        expect(order.shipping_method_id).to be nil
        expect(order.shipments.count).to be 0
        expect(order.adjustments.shipping.count).to be 0
        expect(order.payments.count).to be 1
        expect(order.adjustments.payment_fee.count).to be 1
      end
    end
  end
end
