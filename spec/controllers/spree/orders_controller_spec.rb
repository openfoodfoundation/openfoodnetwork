require 'spec_helper'

describe Spree::OrdersController do
  def current_user
    controller.current_user
  end

  it "selects distributors" do
    d = create(:distributor_enterprise)
    p = create(:product, :distributors => [d])

    spree_get :select_distributor, :id => d.id
    response.should be_redirect

    order = subject.current_order(false)
    order.distributor.should == d
  end

  it "deselects distributors" do
    d = create(:distributor_enterprise)
    p = create(:product, :distributors => [d])
    
    order = subject.current_order(true)
    order.distributor = d
    order.save!

    spree_get :deselect_distributor
    response.should be_redirect

    order.reload
    order.distributor.should be_nil
  end

  describe "adding a product to the cart with a distribution combination that can't service the existing cart" do
    before do
      @request.env["HTTP_REFERER"] = 'http://test.host/'
    end

    pending "errors when an invalid distributor is selected" do
      # Given a product and some distributors
      d1 = create(:distributor_enterprise)
      d2 = create(:distributor_enterprise)
      p = create(:product, :price => 12.34)
      oc = create(:simple_order_cycle, :distributors => [d1], :variants => [p.master])

      # When I attempt to add the product to the cart with an invalid distributor, it should not be added
      expect do
        spree_post :populate, variants: {p.master.id => 1}, distributor_id: d2.id, order_cycle_id: oc.id
        response.should redirect_to :back
      end.to change(self, :num_items_in_cart).by(0)

      # And I should see an error
      flash[:error].should == "That product is not available from the chosen distributor or order cycle."
    end

    pending "errors when an invalid order cycle is selected" do
      # Given a product and some order cycles
      d = create(:distributor_enterprise)
      p = create(:product, :price => 12.34)
      oc1 = create(:simple_order_cycle, :distributors => [d], :variants => [p.master])
      oc2 = create(:simple_order_cycle, :distributors => [d], :variants => [])

      # When I attempt to add the product to my cart with an invalid order cycle, it should not be added
      expect do
        spree_post :populate, variants: {p.master.id => 1}, distributor_id: d.id, order_cycle_id: oc2.id
        response.should redirect_to :back
      end.to change(self, :num_items_in_cart).by(0)

      # And I should see an error
      flash[:error].should == "That product is not available from the chosen distributor or order cycle."
    end

    pending "errors when distribution is valid for the new product but does not cover the cart" do
      # Given two products with different distributors
      d1 = create(:distributor_enterprise)
      d2 = create(:distributor_enterprise)
      p1 = create(:product, :price => 12.34)
      p2 = create(:product, :price => 23.45)
      oc1 = create(:simple_order_cycle, :distributors => [d1], :variants => [p1.master])
      oc2 = create(:simple_order_cycle, :distributors => [d2], :variants => [p2.master])

      # When I add the first to my cart
      expect do
        spree_post :populate, variants: {p1.master.id => 1}, distributor_id: d1.id, order_cycle_id: oc1.id
        response.should redirect_to spree.cart_path
      end.to change(self, :num_items_in_cart).by(1)

      # And I attempt to add the second, then the product should not be added to my cart
      expect do
        spree_post :populate, variants: {p2.master.id => 1}, distributor_id: d2.id, order_cycle_id: oc2.id
        response.should redirect_to :back
      end.to change(self, :num_items_in_cart).by(0)

      # And I should see an error
      flash[:error].should == "That distributor or order cycle can't supply all the products in your cart. Please choose another."
    end
  end

  context "adding a group buy product to the cart" do
    it "sets a variant attribute for the max quantity" do
      distributor_product = create(:distributor_enterprise)
      p = create(:product, :distributors => [distributor_product], :group_buy => true)

      order = subject.current_order(true)
      order.should_receive(:set_variant_attributes).with(p.master, {'max_quantity' => '3'})
      controller.stub(:current_order).and_return(order)

      expect do
        spree_post :populate, :variants => {p.master.id => 1}, :variant_attributes => {p.master.id => {:max_quantity => 3}}, :distributor_id => distributor_product.id
      end.to change(Spree::LineItem, :count).by(1)
    end
  end

  context "removing line items from cart" do
    describe "when I pass params that includes a line item no longer in our cart" do
      it "should silently ignore the missing line item" do
        order = subject.current_order(true)
        li = order.add_variant(create(:simple_product).master)
        spree_get :update, order: { line_items_attributes: {
          "0" => {quantity: "0", id: "9999"},
          "1" => {quantity: "99", id: li.id}
        }}
        response.status.should == 302
        li.reload.quantity.should == 99
      end
    end

    it "filters line items that are missing from params" do
      order = subject.current_order(true)
      li = order.add_variant(create(:simple_product).master)

      attrs = {
        "0" => {quantity: "0", id: "9999"},
        "1" => {quantity: "99", id: li.id}
      }

      controller.remove_missing_line_items(attrs).should == {
        "1" => {quantity: "99", id: li.id}
      }
    end
  end

  context "#populate" do
    let(:user) { create(:user) }
    let(:order) { mock_model(Spree::Order, :number => "R123", :reload => nil, :save! => true, :coupon_code => nil, :user => user, :completed? => false, :currency => "USD", :token => 'a1b2c3d4')}
    let(:populator) { double('OrderPopulator') }
    before do
        order.stub(:last_ip_address=)
        Spree::Order.stub(:find).and_return(order)
        Spree::OrderPopulator.should_receive(:new).and_return(populator)
        Spree::Order.stub(:new).and_return(order)
        if Spree::BaseController.spree_responders[:OrdersController].present?
          Spree::BaseController.spree_responders[:OrdersController].clear
        end
    end

    context "with Variant" do
      it "should handle multiple variants, each with their own quantity" do
        populator.should_receive(:populate).with("variants" => { 1 => "10", 3 => "7" }).and_return(true)
        spree_post :populate, { order_id: order.id, :variants => {1 => 10, 3 => 7} }
      end
    end
  end

  private

  def num_items_in_cart
    Spree::Order.last.andand.line_items.andand.count || 0
  end
end
