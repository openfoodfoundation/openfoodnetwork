require 'spec_helper'
require 'spree/api/testing_support/helpers'
require 'support/request/authentication_workflow'


describe Spree::CheckoutController do
  context "After completing an order" do
    let!(:order) { controller.current_order(true) }

    it "creates a new empty order" do
      controller.reset_order
      expect(controller.session[:order_id]).not_to be_nil
    end

    it "clears the current order cache" do
      controller.reset_order
      expect(controller.current_order).not_to eq order
    end

    it "sets the new order's distributor to the same as the old order" do
      distributor = create(:distributor_enterprise)
      order.set_distributor!(distributor)

      controller.reset_order

      expect(controller.current_order.distributor).to eq distributor
    end

    it "sets the new order's token to the same as the old order, and preserve the access token in the session" do
      controller.reset_order

      expect(controller.current_order.token).to eq order.token
      expect(session[:access_token]).to eq order.token
    end
  end

  context "rendering edit from within spree for the current checkout state" do
    let!(:order) { controller.current_order(true) }
    let!(:line_item) { create(:line_item, order: order) }
    let!(:user) { create(:user) }

    it "redirects to the OFN checkout page" do
      controller.stub(:skip_state_validation?) { true }
      controller.stub(:spree_current_user) { user }
      spree_get :edit
      response.should redirect_to checkout_path
    end
  end
end
