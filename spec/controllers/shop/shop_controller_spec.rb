require 'spec_helper'

describe Shop::ShopController do
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
    end

    describe "returning products" do
      let(:product) { create(:product) }
      let(:order_cycle) { create(:order_cycle, distributors: [d], coordinator: create(:distributor_enterprise)) }
      let(:exchange) { Exchange.find(order_cycle.exchanges.to_enterprises(d).outgoing.first.id) } 

      before do
        exchange.variants << product.master
      end

      it "returns products via json" do
        controller.stub(:current_order_cycle).and_return order_cycle
        xhr :get, :products
        response.should be_success
      end

      it "alphabetizes products" do
        p1 = create(:product, name: "abc")
        p2 = create(:product, name: "def")
        exchange.variants << p1.master
        exchange.variants << p2.master
        controller.stub(:current_order_cycle).and_return order_cycle
        xhr :get, :products
        assigns[:products].should == [p1, p2, product].sort_by{|p| p.name }
      end

      it "does not return products if no order_cycle is selected" do
        controller.stub(:current_order_cycle).and_return nil
        xhr :get, :products
        response.status.should == 404
        response.body.should be_empty
      end

      # TODO: this should be a controller test baby
      pending "filtering products" do
        let(:distributor) { create(:distributor_enterprise) }
        let(:supplier) { create(:supplier_enterprise) }
        let(:oc1) { create(:simple_order_cycle, distributors: [distributor], coordinator: create(:distributor_enterprise), orders_close_at: 2.days.from_now) }
        let(:p1) { create(:simple_product, on_demand: false) }
        let(:p2) { create(:simple_product, on_demand: true) }
        let(:p3) { create(:simple_product, on_demand: false) }
        let(:p4) { create(:simple_product, on_demand: false) }
        let(:p5) { create(:simple_product, on_demand: false) }
        let(:p6) { create(:simple_product, on_demand: false) }
        let(:p7) { create(:simple_product, on_demand: false) }
        let(:v1) { create(:variant, product: p4, unit_value: 2) }
        let(:v2) { create(:variant, product: p4, unit_value: 3, on_demand: false) }
        let(:v3) { create(:variant, product: p4, unit_value: 4, on_demand: true) }
        let(:v4) { create(:variant, product: p5) }
        let(:v5) { create(:variant, product: p5) }
        let(:v6) { create(:variant, product: p7) }
        let(:order) { create(:order, distributor: distributor, order_cycle: order_cycle) }

        before do
          p1.master.count_on_hand = 1
          p2.master.count_on_hand = 0
          p1.master.update_attribute(:count_on_hand, 1)
          p2.master.update_attribute(:count_on_hand, 0)
          p3.master.update_attribute(:count_on_hand, 0)
          p6.master.update_attribute(:count_on_hand, 1)
          p6.delete
          p7.master.update_attribute(:count_on_hand, 1)
          v1.update_attribute(:count_on_hand, 1)
          v2.update_attribute(:count_on_hand, 0)
          v3.update_attribute(:count_on_hand, 0)
          v4.update_attribute(:count_on_hand, 1)
          v5.update_attribute(:count_on_hand, 0)
          v6.update_attribute(:count_on_hand, 1)
          v6.update_attribute(:deleted_at, Time.now)
          exchange = Exchange.find(oc1.exchanges.to_enterprises(distributor).outgoing.first.id) 
          exchange.update_attribute :pickup_time, "frogs" 
          exchange.variants << p1.master
          exchange.variants << p2.master
          exchange.variants << p3.master
          exchange.variants << p6.master
          exchange.variants << v1
          exchange.variants << v2
          exchange.variants << v3
          # v4 is in stock but not in distribution
          # v5 is out of stock and in the distribution
          # Neither should display, nor should their product, p5
          exchange.variants << v5
          exchange.variants << v6

          controller.stub(:current_order).and_return order
          visit shop_path
        end

        it "filters products based on availability" do
          # It shows on hand products
          page.should have_content p1.name
          page.should have_content p4.name

          # It shows on demand products
          page.should have_content p2.name

          # It does not show products that are neither on hand or on demand
          page.should_not have_content p3.name

          # It shows on demand variants
          page.should have_content v3.options_text

          # It does not show variants that are neither on hand or on demand
          page.should_not have_content v2.options_text

          # It does not show products that have no available variants in this distribution
          page.should_not have_content p5.name

          # It does not show deleted products
          page.should_not have_content p6.name

          # It does not show deleted variants
          page.should_not have_content v6.name
          page.should_not have_content p7.name
        end
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

        it "returns price including fees" do
          Spree::Variant.any_instance.stub(:price_with_fees).and_return 998.00
          xhr :get, :products
          response.body.should have_content "998.0"
        end
      end
    end
  end
end
