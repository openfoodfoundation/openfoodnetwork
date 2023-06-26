# frozen_string_literal: true

require 'spec_helper'

describe EnterprisesController, type: :controller do
  describe "shopping for a distributor" do
    let(:user) { create(:user) }
    let(:order) { controller.current_order(true) }
    let(:line_item) { create(:line_item) }
    let!(:current_distributor) { create(:distributor_enterprise, with_payment_and_shipping: true) }
    let!(:distributor) { create(:distributor_enterprise, with_payment_and_shipping: true) }
    let!(:order_cycle1) {
      create(:simple_order_cycle, distributors: [distributor], orders_open_at: 2.days.ago,
                                  orders_close_at: 3.days.from_now, variants: [line_item.variant] )
    }
    let!(:order_cycle2) {
      create(:simple_order_cycle, distributors: [distributor], orders_open_at: 3.days.ago,
                                  orders_close_at: 4.days.from_now )
    }

    before do
      order.set_distributor! current_distributor
      order.line_items << line_item
    end

    it "sets the shop as the distributor on the order when shopping for the distributor" do
      get :shop, params: { id: distributor }

      expect(controller.current_distributor).to eq(distributor)
      expect(controller.current_order.distributor).to eq(distributor)
      expect(controller.current_order.order_cycle).to be_nil
    end

    context "when user is logged in" do
      before { allow(controller).to receive(:spree_current_user) { user } }

      it "sets the shop as the distributor on the order when shopping for the distributor" do
        get :shop, params: { id: distributor }

        expect(controller.current_distributor).to eq(distributor)
        expect(controller.current_order.distributor).to eq(distributor)
        expect(controller.current_order.order_cycle).to be_nil
      end
    end

    it "sorts order cycles by the distributor's preferred ordering attr" do
      distributor.update_attribute(:preferred_shopfront_order_cycle_order, 'orders_close_at')
      get :shop, params: { id: distributor }
      expect(assigns(:order_cycles)).to eq([order_cycle1, order_cycle2].sort_by(&:orders_close_at))

      distributor.update_attribute(:preferred_shopfront_order_cycle_order, 'orders_open_at')
      get :shop, params: { id: distributor }
      expect(assigns(:order_cycles)).to eq([order_cycle1, order_cycle2].sort_by(&:orders_open_at))
    end

    context "using FilterOrderCycles tag rules" do
      let!(:order_cycle3) {
        create(:simple_order_cycle, distributors: [distributor], orders_open_at: 3.days.ago,
                                    orders_close_at: 4.days.from_now)
      }
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

        get :shop, params: { id: distributor }
        expect(assigns(:order_cycles)).to include order_cycle1, order_cycle2, order_cycle3

        allow(controller).to receive(:spree_current_user) { user }

        get :shop, params: { id: distributor }
        expect(assigns(:order_cycles)).to include order_cycle1, order_cycle2, order_cycle3

        oc3_exchange.update_attribute(:tag_list, "wholesale")

        get :shop, params: { id: distributor }
        expect(assigns(:order_cycles)).to include order_cycle1, order_cycle2
        expect(assigns(:order_cycles)).not_to include order_cycle3

        customer.update_attribute(:tag_list, ["wholesale"])

        get :shop, params: { id: distributor }
        expect(assigns(:order_cycles)).to include order_cycle1, order_cycle2, order_cycle3
      end
    end

    it "empties an order set for a previous distributor, when shopping at a new distributor" do
      line_item = create(:line_item)
      controller.current_order.line_items << line_item

      get :shop, params: { id: distributor }

      expect(controller.current_order.distributor).to eq(distributor)
      expect(controller.current_order.order_cycle).to be_nil
      expect(controller.current_order.line_items.size).to eq(0)
    end

    it "should not empty an order if returning to the same distributor" do
      get :shop, params: { id: current_distributor }

      expect(controller.current_order.distributor).to eq current_distributor
      expect(controller.current_order.line_items.first.variant).to eq line_item.variant
    end

    describe "when an out of stock item is in the cart" do
      let(:variant) { create(:variant, on_demand: false, on_hand: 10) }
      let(:line_item) { create(:line_item, variant: variant) }
      let(:order_cycle) {
        create(:simple_order_cycle, distributors: [current_distributor], variants: [variant])
      }

      before do
        order.set_distribution! current_distributor, order_cycle
        order.line_items << line_item

        variant.on_hand = 0
        variant.save!
      end

      it "redirects to the cart" do
        get :shop, params: { id: current_distributor }

        expect(response).to redirect_to cart_path
      end
    end

    it "resets order if the order cycle of the current order is no longer open or visible" do
      order.distributor = distributor
      order.order_cycle = order_cycle1
      order.save
      order_cycle1.update_attribute :orders_close_at, Time.zone.now

      get :shop, params: { id: distributor }

      expect(controller.current_order.distributor).to eq(distributor)
      expect(controller.current_order.order_cycle).to eq(order_cycle2)
      expect(controller.current_order.line_items).to be_empty
    end

    it "sets order cycle if only one is available at the chosen distributor" do
      order_cycle2.destroy

      get :shop, params: { id: distributor }

      expect(controller.current_order.distributor).to eq(distributor)
      expect(controller.current_order.order_cycle).to eq(order_cycle1)
    end
  end

  context "checking permalink availability" do
    # let(:enterprise) { create(:enterprise, permalink: 'enterprise_permalink') }

    it "responds with status of 200 when the route does not exist" do
      get :check_permalink, xhr: true, params: { permalink: 'some_nonexistent_route' }, as: :js
      expect(response.status).to be 200
    end

    it "responds with status of 409 when the permalink matches an existing route" do
      # get :check_permalink, { permalink: 'enterprise_permalink', format: :js }
      # expect(response.status).to be 409
      get :check_permalink, xhr: true, params: { permalink: 'map' }, as: :js
      expect(response.status).to be 409
      get :check_permalink, xhr: true, params: { permalink: '' }, as: :js
      expect(response.status).to be 409
    end
  end

  context "checking access on nonexistent enterprise" do
    before do
      get :shop, params: { id: "some_nonexistent_enterprise" }
    end

    it "redirects to shops_path" do
      expect(response).to redirect_to shops_path
    end

    it "shows a flash message with the error" do
      expect(request.flash[:error]).to eq('The shop you are looking for doesn\'t exist or ' \
                                          'is inactive on OFN. Please check other shops.')
    end
  end
end
