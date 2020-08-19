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

    it "creates a new order" do
      expect {
        controller.current_order(true)
      }.to change { Spree::Order.count }.by(1)
    end

    it "associates the current user" do
      allow(controller).to receive(:spree_current_user).and_return(user)
      order = controller.current_order(true)
      expect(user.orders.reload).to eq [order]
    end

    it "loads the order referenced in the session" do
      cart = create(:order, user: user, created_by: user, state: "cart", completed_at: nil)
      session[:order_id] = cart.id

      expect(controller.current_order).to eq cart
    end

    it "applies variant overrides" do
      shop = create(:distributor_enterprise)
      variant = create(:variant, price: 3)
      create(:variant_override, variant: variant, hub: shop, price: 5)
      cart = create(
        :order,
        user: user,
        created_by: user,
        distributor: shop,
        state: "cart",
        completed_at: nil
      )
      cart.line_items << create(:line_item, variant: variant)
      session[:order_id] = cart.id

      expect(controller.current_order.line_items.first.variant.price).to eq 5
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
