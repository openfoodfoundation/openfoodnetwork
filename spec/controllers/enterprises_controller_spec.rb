require 'spec_helper'

describe EnterprisesController do
  it "displays suppliers" do
    s = create(:supplier_enterprise)
    d = create(:distributor_enterprise)

    spree_get :suppliers

    assigns(:suppliers).should == [s]
  end

  describe "displaying an enterprise and its products" do
    let(:p)   { create(:simple_product, supplier: s) }
    let(:s)   { create(:supplier_enterprise) }
    let!(:c)  { create(:distributor_enterprise) }
    let(:d1)  { create(:distributor_enterprise) }
    let(:d2)  { create(:distributor_enterprise) }
    let(:oc1) { create(:simple_order_cycle) }
    let(:oc2) { create(:simple_order_cycle) }

    it "displays products for the selected (order_cycle -> outgoing exchange)" do
      create(:exchange, order_cycle: oc1, sender: s, receiver: c, incoming: true, variants: [p.master])
      create(:exchange, order_cycle: oc1, sender: c, receiver: d1, incoming: false, variants: [p.master])

      controller.stub(:current_distributor) { d1 }
      controller.stub(:current_order_cycle) { oc1 }

      spree_get :show, {id: d1}

      assigns(:products).should include p
    end

    it "does not display other products in the order cycle or in the distributor" do
      # Given a product that is in this order cycle on a different distributor
      create(:exchange, order_cycle: oc1, sender: s, receiver: c, incoming: true, variants: [p.master])
      create(:exchange, order_cycle: oc1, sender: c, receiver: d2, incoming: false, variants: [p.master])

      # And is also in this distributor in a different order cycle
      create(:exchange, order_cycle: oc2, sender: s, receiver: c, incoming: true, variants: [p.master])
      create(:exchange, order_cycle: oc2, sender: c, receiver: d1, incoming: false, variants: [p.master])

      # When I view the enterprise page for d1 x oc1
      controller.stub(:current_distributor) { d1 }
      controller.stub(:current_order_cycle) { oc1 }
      spree_get :show, {id: d1}

      # Then I should not see the product
      assigns(:products).should_not include p
    end

  end

  describe "shopping for a distributor" do

    before(:each) do
      @current_distributor = create(:distributor_enterprise)
      @distributor = create(:distributor_enterprise)
      @order_cycle1 = create(:simple_order_cycle, distributors: [@distributor])
      @order_cycle2 = create(:simple_order_cycle, distributors: [@distributor])
      controller.current_order(true).distributor = @current_distributor
    end

    it "sets the shop as the distributor on the order when shopping for the distributor" do
      spree_get :shop, {id: @distributor}

      controller.current_order.distributor.should == @distributor
      controller.current_order.order_cycle.should be_nil
    end

    it "empties an order that was set for a previous distributor, when shopping at a new distributor" do
      line_item = create(:line_item)
      controller.current_order.line_items << line_item

      spree_get :shop, {id: @distributor}

      controller.current_order.distributor.should == @distributor
      controller.current_order.order_cycle.should be_nil
      controller.current_order.line_items.size.should == 0
    end

    it "should not empty an order if returning to the same distributor" do
      product = create(:product)
      create(:product_distribution, product: product, distributor: @current_distributor)
      line_item = create(:line_item, variant: product.master)
      controller.current_order.line_items << line_item

      spree_get :shop, {id: @current_distributor}

      controller.current_order.distributor.should == @current_distributor
      controller.current_order.order_cycle.should be_nil
      controller.current_order.line_items.size.should == 1
    end

    it "sets order cycle if only one is available at the chosen distributor" do
      @order_cycle2.destroy

      spree_get :shop, {id: @distributor}

      controller.current_order.distributor.should == @distributor
      controller.current_order.order_cycle.should == @order_cycle1
    end
  end

  context "when a distributor has not been chosen" do
    it "redirects #show to distributor selection" do
      @distributor = create(:distributor_enterprise)
      spree_get :show, {id: @distributor}
      response.should redirect_to spree.root_path
    end
  end

  describe "BaseController: handling order cycles closing mid-order" do
    it "clears the order and displays an expiry message" do
      oc = double(:order_cycle, id: 123, closed?: true)
      controller.stub(:current_order_cycle) { oc }

      order = double(:order)
      order.should_receive(:empty!)
      order.should_receive(:set_order_cycle!).with(nil)
      controller.stub(:current_order) { order }

      spree_get :index
      session[:expired_order_cycle_id].should == 123
      response.should redirect_to spree.order_cycle_expired_orders_path
    end
  end
end
