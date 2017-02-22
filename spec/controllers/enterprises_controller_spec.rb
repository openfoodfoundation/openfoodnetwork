require 'spec_helper'

describe EnterprisesController, type: :controller do
  describe "shopping for a distributor" do
    let(:order) { controller.current_order(true) }


    let!(:current_distributor) { create(:distributor_enterprise, with_payment_and_shipping: true) }
    let!(:distributor) { create(:distributor_enterprise, with_payment_and_shipping: true) }
    let!(:order_cycle1) { create(:simple_order_cycle, distributors: [distributor], orders_open_at: 2.days.ago, orders_close_at: 3.days.from_now ) }
    let!(:order_cycle2) { create(:simple_order_cycle, distributors: [distributor], orders_open_at: 3.days.ago, orders_close_at: 4.days.from_now ) }

    before do
      order.set_distributor! current_distributor
    end

    it "sets the shop as the distributor on the order when shopping for the distributor" do
      spree_get :shop, {id: distributor}

      controller.current_order.distributor.should == distributor
      controller.current_order.order_cycle.should be_nil
    end

    it "sorts order cycles by the distributor's preferred ordering attr" do
      distributor.update_attribute(:preferred_shopfront_order_cycle_order, 'orders_close_at')
      spree_get :shop, {id: distributor}
      assigns(:order_cycles).should == [order_cycle1, order_cycle2].sort_by(&:orders_close_at)

      distributor.update_attribute(:preferred_shopfront_order_cycle_order, 'orders_open_at')
      spree_get :shop, {id: distributor}
      assigns(:order_cycles).should == [order_cycle1, order_cycle2].sort_by(&:orders_open_at)
    end

    context "using FilterOrderCycles tag rules" do
      let(:user) { create(:user) }
      let!(:order_cycle3) { create(:simple_order_cycle, distributors: [distributor], orders_open_at: 3.days.ago, orders_close_at: 4.days.from_now) }
      let!(:oc3_exchange) { order_cycle3.exchanges.outgoing.to_enterprise(distributor).first }
      let(:customer) { create(:customer, user: user, enterprise: distributor) }

      it "shows order cycles allowed by the rules" do
        create(:filter_order_cycles_tag_rule,
          enterprise: distributor,
          preferred_customer_tags: "wholesale",
          preferred_exchange_tags: "wholesale",
          preferred_matched_order_cycles_visibility: 'visible')
        create(:filter_order_cycles_tag_rule,
          enterprise: distributor,
          is_default: true,
          preferred_exchange_tags: "wholesale",
          preferred_matched_order_cycles_visibility: 'hidden')

        spree_get :shop, {id: distributor}
        expect(assigns(:order_cycles)).to include order_cycle1, order_cycle2, order_cycle3

        allow(controller).to receive(:spree_current_user) { user }

        spree_get :shop, {id: distributor}
        expect(assigns(:order_cycles)).to include order_cycle1, order_cycle2, order_cycle3

        oc3_exchange.update_attribute(:tag_list, "wholesale")

        spree_get :shop, {id: distributor}
        expect(assigns(:order_cycles)).to include order_cycle1, order_cycle2
        expect(assigns(:order_cycles)).not_to include order_cycle3

        customer.update_attribute(:tag_list, ["wholesale"])

        spree_get :shop, {id: distributor}
        expect(assigns(:order_cycles)).to include order_cycle1, order_cycle2, order_cycle3
      end
    end

    it "empties an order that was set for a previous distributor, when shopping at a new distributor" do
      line_item = create(:line_item)
      controller.current_order.line_items << line_item

      spree_get :shop, {id: distributor}

      controller.current_order.distributor.should == distributor
      controller.current_order.order_cycle.should be_nil
      controller.current_order.line_items.size.should == 0
    end

    it "should not empty an order if returning to the same distributor" do
      product = create(:product)
      create(:product_distribution, product: product, distributor: current_distributor)
      line_item = create(:line_item, variant: product.master)
      controller.current_order.line_items << line_item

      spree_get :shop, {id: current_distributor}

      controller.current_order.distributor.should == current_distributor
      controller.current_order.order_cycle.should be_nil
      controller.current_order.line_items.size.should == 1
    end

    describe "when an out of stock item is in the cart" do
      let(:variant) { create(:variant, on_demand: false, on_hand: 10) }
      let(:line_item) { create(:line_item, variant: variant) }
      let(:order_cycle) { create(:simple_order_cycle, distributors: [distributor], variants: [variant]) }

      before do
        order.set_distribution! current_distributor, order_cycle
        order.line_items << line_item

        Spree::Config.set allow_backorders: false
        variant.on_hand = 0
        variant.save!
      end

      it "redirects to the cart" do
        spree_get :shop, {id: current_distributor}

        response.should redirect_to spree.cart_path
      end
    end

    it "sets order cycle if only one is available at the chosen distributor" do
      order_cycle2.destroy

      spree_get :shop, {id: distributor}

      controller.current_order.distributor.should == distributor
      controller.current_order.order_cycle.should == order_cycle1
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
