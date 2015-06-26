require 'spec_helper'

describe EnterprisesController do
  describe "shopping for a distributor" do

    before(:each) do
      @current_distributor = create(:distributor_enterprise, with_payment_and_shipping: true)
      @distributor = create(:distributor_enterprise, with_payment_and_shipping: true)
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

  context "checking permalink availability" do
    # let(:enterprise) { create(:enterprise, permalink: 'enterprise_permalink') }

    it "responds with status of 200 when the route does not exist" do
      spree_get :check_permalink, { permalink: 'some_nonexistent_route', format: :js }
      expect(response.status).to be 200
    end

    it "responds with status of 409 when the permalink matches an existing route" do
      # spree_get :check_permalink, { permalink: 'enterprise_permalink', format: :js }
      # expect(response.status).to be 409
      spree_get :check_permalink, { permalink: 'map', format: :js }
      expect(response.status).to be 409
      spree_get :check_permalink, { permalink: '', format: :js }
      expect(response.status).to be 409
    end
  end
end
