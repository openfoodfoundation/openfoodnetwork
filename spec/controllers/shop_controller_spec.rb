require 'spec_helper'

describe ShopController do
  let(:distributor) { create(:distributor_enterprise) }

  it "redirects to the home page if no distributor is selected" do
    spree_get :show
    response.should redirect_to root_path
  end


  describe "with a distributor in place" do
    before do
      controller.stub(:current_distributor).and_return distributor
    end

    describe "selecting an order cycle" do
      it "should select an order cycle when only one order cycle is open" do
        oc1 = create(:simple_order_cycle, distributors: [distributor])
        spree_get :show
        controller.current_order_cycle.should == oc1
      end

      it "should not set an order cycle when multiple order cycles are open" do
        oc1 = create(:simple_order_cycle, distributors: [distributor])
        oc2 = create(:simple_order_cycle, distributors: [distributor])
        spree_get :show
        controller.current_order_cycle.should be_nil
      end

      it "should allow the user to post to select the current order cycle" do
        oc1 = create(:simple_order_cycle, distributors: [distributor])
        oc2 = create(:simple_order_cycle, distributors: [distributor])

        spree_post :order_cycle, order_cycle_id: oc2.id
        response.should be_success
        controller.current_order_cycle.should == oc2
      end

      context "JSON tests" do
        render_views

        it "should return the order cycle details when the OC is selected" do
          oc1 = create(:simple_order_cycle, distributors: [distributor])
          oc2 = create(:simple_order_cycle, distributors: [distributor])

          spree_post :order_cycle, order_cycle_id: oc2.id
          response.should be_success
          response.body.should have_content oc2.id
        end

        it "should return the current order cycle when hit with GET" do
          oc1 = create(:simple_order_cycle, distributors: [distributor])
          controller.stub(:current_order_cycle).and_return oc1
          spree_get :order_cycle
          response.body.should have_content oc1.id
        end
      end

      it "should not allow the user to select an invalid order cycle" do
        oc1 = create(:simple_order_cycle, distributors: [distributor])
        oc2 = create(:simple_order_cycle, distributors: [distributor])
        oc3 = create(:simple_order_cycle, distributors: [create(:distributor_enterprise)])

        spree_post :order_cycle, order_cycle_id: oc3.id
        response.status.should == 404
        controller.current_order_cycle.should be_nil
      end
    end


    describe "producers/suppliers" do
      let(:supplier) { create(:supplier_enterprise) }
      let(:product) { create(:product, supplier: supplier) }
      let(:order_cycle) { create(:simple_order_cycle, distributors: [distributor]) }

      before do
        exchange = order_cycle.exchanges.to_enterprises(distributor).outgoing.first
        exchange.variants << product.master
      end
    end

    describe "returning products" do
      let(:order_cycle) { create(:simple_order_cycle, distributors: [distributor]) }
      let(:exchange) { order_cycle.exchanges.to_enterprises(distributor).outgoing.first }

      describe "requests and responses" do
        let(:product) { create(:product) }

        before do
          exchange.variants << product.variants.first
        end

        it "returns products via JSON" do
          controller.stub(:current_order_cycle).and_return order_cycle
          xhr :get, :products
          response.should be_success
        end

        it "does not return products if no order cycle is selected" do
          controller.stub(:current_order_cycle).and_return nil
          xhr :get, :products
          response.status.should == 404
          response.body.should be_empty
        end
      end
    end
  end
end
