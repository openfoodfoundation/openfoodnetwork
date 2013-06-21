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

    it "produces an error when the distributor does not distribute the product" do
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
        spree_post :populate, variants: {p2.master.id => 1}, distributor_id: d1.id, order_cycle_id: oc1.id
        response.should redirect_to :back
      end.to change(self, :num_items_in_cart).by(0)

      # And I should see an error
      flash[:error].should == "That product is not available from the chosen distributor or order cycle."
    end

    it "produces an error when the order cycle does not distribute the product" do
      # Given two products with the same distributor but different order cycles
      d = create(:distributor_enterprise)
      p1 = create(:product, :price => 12.34)
      p2 = create(:product, :price => 23.45)
      oc1 = create(:simple_order_cycle, :distributors => [d], :variants => [p1.master])
      oc2 = create(:simple_order_cycle, :distributors => [d], :variants => [p2.master])

      # When I add the first to my cart
      expect do
        spree_post :populate, variants: {p1.master.id => 1}, distributor_id: d.id, order_cycle_id: oc1.id
        response.should redirect_to spree.cart_path
      end.to change(self, :num_items_in_cart).by(1)

      # And I attempt to add the second, then the product should not be added to my cart
      expect do
        spree_post :populate, variants: {p2.master.id => 1}, distributor_id: d.id, order_cycle_id: oc1.id
        response.should redirect_to :back
      end.to change(self, :num_items_in_cart).by(0)

      # And I should see an error
      flash[:error].should == "That product is not available from the chosen distributor or order cycle."
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


  private

  def num_items_in_cart
    Spree::Order.last.andand.line_items.andand.count || 0
  end

end
