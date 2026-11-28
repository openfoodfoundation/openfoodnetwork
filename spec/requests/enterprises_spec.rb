# frozen_string_literal: true

RSpec.describe EnterprisesController do
  describe "GET /enterprises/:permalink" do
    # `resources :enterprises` used to generate a `show` route which matched
    # first and raised, because the controller has no `show` action.
    it "redirects legacy enterprise URLs to the home page" do
      get "/enterprises/some-old-permalink"

      expect(response).to redirect_to("/")
    end
  end

  describe "GET /:permalink/shop from a placed order's 'Add products' button" do
    include_context "session helper"

    let(:user) { create(:user) }
    let(:distributor) { create(:distributor_enterprise, with_payment_and_shipping: true) }
    let(:variant) { create(:variant) }
    let!(:first_order_cycle) {
      create(:simple_order_cycle, distributors: [distributor], variants: [variant])
    }
    let!(:second_order_cycle) {
      create(:simple_order_cycle, distributors: [distributor], variants: [variant])
    }
    let(:cart) { create(:order, user:, distributor:) }

    before do
      session_hash[:order_id] = cart.id
      sign_in user
    end

    def add_products(order_cycle_id:)
      get enterprise_shop_path(distributor, order_cycle_id:, add_to_order: "R123456789")
    end

    it "opens the shop in the order's order cycle and remembers the order" do
      add_products(order_cycle_id: second_order_cycle.id)

      expect(response).to have_http_status :ok
      expect(cart.reload.order_cycle).to eq second_order_cycle
      expect(session_hash[:add_to_order]).to eq "R123456789"
    end

    it "keeps the order cycle of a cart the customer already started" do
      cart.update!(order_cycle: first_order_cycle)
      create(:line_item, order: cart, variant:)

      add_products(order_cycle_id: second_order_cycle.id)

      expect(cart.reload.order_cycle).to eq first_order_cycle
      expect(cart.line_items.count).to eq 1
    end

    it "ignores an order cycle the shop doesn't offer" do
      other_order_cycle = create(:simple_order_cycle)

      add_products(order_cycle_id: other_order_cycle.id)

      expect(cart.reload.order_cycle).to be_nil
    end
  end
end
