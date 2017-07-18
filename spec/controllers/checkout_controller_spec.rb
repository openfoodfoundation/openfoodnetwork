require 'spec_helper'

describe CheckoutController do
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
      allow(ResetOrderService).to receive(:new).with(controller, order) { reset_order_service }
      expect(reset_order_service).to receive(:call)

      order.stub(:update_attributes).and_return true
      order.stub(:state).and_return "complete"

      xhr :post, :update, order: {}, use_route: :spree
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

        xhr :post, :update, order: {}, use_route: :spree
        response.status.should == 200
      end

      it "tries a maximum of 3 times before giving up and returning an error" do
        order.stub(:update_attributes).and_return true
        order.stub(:next) { raise ActiveRecord::StaleObjectError.new(Spree::Variant.new, 'update') }

        xhr :post, :update, order: {}, use_route: :spree
        response.status.should == 400
      end
    end
  end

  describe "Paypal routing" do
    let(:payment_method) { create(:payment_method, type: "Spree::Gateway::PayPalExpress") }
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
  end
end
