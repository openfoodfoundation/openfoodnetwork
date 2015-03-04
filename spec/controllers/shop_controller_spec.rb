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
        oc1 = create(:simple_order_cycle, distributors: [d])
        spree_get :show
        controller.current_order_cycle.should == oc1
      end

      it "should not set an order cycle when multiple order cycles are open" do
        oc1 = create(:simple_order_cycle, distributors: [d])
        oc2 = create(:simple_order_cycle, distributors: [d])
        spree_get :show
        controller.current_order_cycle.should == nil
      end

      it "should allow the user to post to select the current order cycle" do
        oc1 = create(:simple_order_cycle, distributors: [d])
        oc2 = create(:simple_order_cycle, distributors: [d])

        spree_post :order_cycle, order_cycle_id: oc2.id
        response.should be_success
        controller.current_order_cycle.should == oc2
      end

      context "RABL tests" do
        render_views
        it "should return the order cycle details when the oc is selected" do
          oc1 = create(:simple_order_cycle, distributors: [d])
          oc2 = create(:simple_order_cycle, distributors: [d])

          spree_post :order_cycle, order_cycle_id: oc2.id
          response.should be_success
          response.body.should have_content oc2.id
        end

        it "should return the current order cycle when hit with GET" do
          oc1 = create(:simple_order_cycle, distributors: [d])
          controller.stub(:current_order_cycle).and_return oc1
          spree_get :order_cycle
          response.body.should have_content oc1.id
        end
      end

      it "should not allow the user to select an invalid order cycle" do
        oc1 = create(:simple_order_cycle, distributors: [d])
        oc2 = create(:simple_order_cycle, distributors: [d])
        oc3 = create(:simple_order_cycle, distributors: [create(:distributor_enterprise)])

        spree_post :order_cycle, order_cycle_id: oc3.id
        response.status.should == 404
        controller.current_order_cycle.should == nil
      end
    end


    describe "producers/suppliers" do
      let(:supplier) { create(:supplier_enterprise) }
      let(:product) { create(:product, supplier: supplier) }
      let(:order_cycle) { create(:simple_order_cycle, distributors: [d], coordinator: create(:distributor_enterprise)) }

      before do
        exchange = Exchange.find(order_cycle.exchanges.to_enterprises(d).outgoing.first.id)
        exchange.variants << product.master
      end
    end

    describe "returning products" do
      let(:order_cycle) { create(:simple_order_cycle, distributors: [d], coordinator: create(:distributor_enterprise)) }
      let(:exchange) { Exchange.find(order_cycle.exchanges.to_enterprises(d).outgoing.first.id) }

      describe "requests and responses" do
        let(:product) { create(:product) }
        before do
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
      end

      describe "sorting" do
        let(:t1) { create(:taxon) }
        let(:t2) { create(:taxon) }
        let!(:p1) { create(:product, name: "abc", primary_taxon_id: t2.id) }
        let!(:p2) { create(:product, name: "def", primary_taxon_id: t1.id) }
        let!(:p3) { create(:product, name: "ghi", primary_taxon_id: t2.id) }
        let!(:p4) { create(:product, name: "jkl", primary_taxon_id: t1.id) }

        before do
          exchange.variants << p1.master
          exchange.variants << p2.master
          exchange.variants << p3.master
          exchange.variants << p4.master
        end

        it "sorts products by the distributor's preferred taxon list" do
          d.stub(:preferred_shopfront_taxon_order) {"#{t1.id},#{t2.id}"}
          controller.stub(:current_order_cycle).and_return order_cycle
          xhr :get, :products
          assigns[:products].should == [p2, p4, p1, p3]
        end

        it "alphabetizes products by name when taxon list is not set" do
          d.stub(:preferred_shopfront_taxon_order) {""}
          controller.stub(:current_order_cycle).and_return order_cycle
          xhr :get, :products
          assigns[:products].should == [p1, p2, p3, p4]
        end
      end

      context "RABL tests" do
        render_views
        let(:product) { create(:product) }

        before do
          exchange.variants << product.master
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

        it "includes the primary taxon" do
          taxon = create(:taxon)
          Spree::Product.any_instance.stub(:primary_taxon).and_return taxon
          xhr :get, :products
          response.body.should have_content taxon.name
        end
      end
    end
  end
end
