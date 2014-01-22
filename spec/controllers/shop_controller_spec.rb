require 'spec_helper'

describe ShopController do
  let(:d) { create(:distributor_enterprise) }

  it "redirects to the home page if no distributor is selected" do
    spree_get :show
    response.should redirect_to root_path
  end


  describe "with a distributor in place" do
    before do
      controller.stub(:current_distributor).and_return d
    end

    describe "Selecting order cycles" do
      it "should select an order cycle when only one order cycle is open" do
        oc1 = create(:order_cycle, distributors: [d])
        spree_get :show
        controller.current_order_cycle.should == oc1
      end

      it "should not set an order cycle when multiple order cycles are open" do
        oc1 = create(:order_cycle, distributors: [d])
        oc2 = create(:order_cycle, distributors: [d])
        spree_get :show
        controller.current_order_cycle.should == nil
      end
      
      it "should allow the user to post to select the current order cycle" do
        oc1 = create(:order_cycle, distributors: [d])
        oc2 = create(:order_cycle, distributors: [d])
        
        spree_post :order_cycle, order_cycle_id: oc2.id
        response.should be_success
        controller.current_order_cycle.should == oc2
      end

      context "RABL tests" do
        render_views 
        it "should return the order cycle details when the oc is selected" do
          oc1 = create(:order_cycle, distributors: [d])
          oc2 = create(:order_cycle, distributors: [d])
          
          spree_post :order_cycle, order_cycle_id: oc2.id
          response.should be_success
          response.body.should have_content oc2.id 
        end

        it "should return the current order cycle when hit with GET" do
          oc1 = create(:order_cycle, distributors: [d])
          controller.stub(:current_order_cycle).and_return oc1
          spree_get :order_cycle
          response.body.should have_content oc1.id
        end
      end

      it "should not allow the user to select an invalid order cycle" do
        oc1 = create(:order_cycle, distributors: [d])
        oc2 = create(:order_cycle, distributors: [d])
        oc3 = create(:order_cycle, distributors: [create(:distributor_enterprise)])
        
        spree_post :order_cycle, order_cycle_id: oc3.id
        response.status.should == 404
        controller.current_order_cycle.should == nil
      end
    end


    describe "producers/suppliers" do
      let(:supplier) { create(:supplier_enterprise) }
      let(:product) { create(:product, supplier: supplier) }
      let(:order_cycle) { create(:order_cycle, distributors: [d], coordinator: create(:distributor_enterprise)) }

      before do
        exchange = Exchange.find(order_cycle.exchanges.to_enterprises(d).outgoing.first.id) 
        exchange.variants << product.master
      end

      it "builds a list of producers/suppliers" do
        spree_get :show
        assigns[:producers].should == [supplier]
      end
    end

    describe "returning products" do
      let(:product) { create(:product) }
      let(:order_cycle) { create(:order_cycle, distributors: [d], coordinator: create(:distributor_enterprise)) }

      before do
        exchange = Exchange.find(order_cycle.exchanges.to_enterprises(d).outgoing.first.id) 
        exchange.variants << product.master
      end

      it "returns products via json" do
        controller.stub(:current_order_cycle).and_return order_cycle
        xhr :get, :products
        response.should be_success
      end

      it "does not return products if no order_cycle is selected" do
        controller.stub(:current_order_cycle).and_return nil
        xhr :get, :products
        response.status.should == 404
        response.body.should be_empty
      end

      context "RABL tests" do
        render_views
        before do
          controller.stub(:current_order_cycle).and_return order_cycle
        end
        it "only returns products for the current order cycle" do
          xhr :get, :products
          response.body.should have_content product.name
        end

        it "doesn't return products not in stock" do
          product.update_attribute(:on_demand, false)
          product.master.update_attribute(:count_on_hand, 0)
          xhr :get, :products
          response.body.should_not have_content product.name
        end
        it "strips html from description" do
          product.update_attribute(:description, "<a href='44'>turtles</a> frogs")
          xhr :get, :products
          response.body.should have_content "frogs"
          response.body.should_not have_content "<a href"
        end
      end
    end
  end
end
