require 'spec_helper'

describe BaseController, type: :controller do
  let(:oc)    { instance_double(OrderCycle, id: 1) }
  let(:order) { instance_double(Spree::Order) }
  controller(BaseController) do
    def index
      render text: ""
    end
  end

  describe "#current_order" do
    let(:user) { create(:user) }

    it "doesn't change anything without a user" do
      expect {
        get :index
      }.to_not change { Spree::Order.count }
    end

    it "creates a new order" do
      allow(controller).to receive(:try_spree_current_user).and_return(user)

      expect {
        get :index
      }.to change { Spree::Order.count }.by(1)

      expect(user.orders.count).to eq 1
    end

    it "uses the last incomplete order" do
      last_cart = create(:order, user: user, created_by: user, state: "cart", completed_at: nil)
      allow(controller).to receive(:try_spree_current_user).and_return(user)

      expect {
        get :index
      }.to_not change { Spree::Order.count }

      expect(session[:order_id]).to eq last_cart.id
    end

    # This behaviour comes from spree_core/lib/spree/core/controller_helpers/order.rb.
    # It should be overridden by our lib/spree/core/controller_helpers/order.rb.
    # But this test case proves that the original Spree logic is active.
    #
    # We originally overrode the Spree logic because merging orders from different
    # shops was confusing. Incomplete orders would also re-appear after checkout,
    # confusing as well.
    #
    # When we brought this code from Spree and merged it with our overrides,
    # we accidentally started using Spree's version again.
    it "merges the last incomplete order into the current one" do
      last_cart = create(:order, user: user, created_by: user, state: "cart", completed_at: nil)
      last_cart.line_items << create(:line_item)

      current_cart = create(
        :order,
        user: user,
        created_by: user,
        state: "cart",
        completed_at: nil,
        created_at: 1.week.ago
      )
      session[:order_id] = current_cart.id

      allow(controller).to receive(:try_spree_current_user).and_return(user)

      expect {
        get :index
      }.to_not change { session[:order_id] }

      expect(current_cart.line_items.pluck(:id)).to match_array last_cart.line_items.map(&:id)
    end
  end

  it "redirects to home with message if order cycle is expired" do
    expect(controller).to receive(:current_order_cycle).and_return(oc).twice
    expect(controller).to receive(:current_order).and_return(order).twice
    expect(oc).to receive(:closed?).and_return(true)
    expect(order).to receive(:empty!)
    expect(order).to receive(:set_order_cycle!).with(nil)

    get :index

    expect(session[:expired_order_cycle_id]).to eq oc.id
    expect(response).to redirect_to root_url
    expect(flash[:info]).to eq I18n.t('order_cycle_closed')
  end
end
