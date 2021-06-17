# frozen_string_literal: true

require 'spec_helper'

describe ShopController, type: :controller do
  let!(:pm) { create(:payment_method) }
  let!(:sm) { create(:shipping_method) }
  let(:distributor) {
    create(:distributor_enterprise, payment_methods: [pm], shipping_methods: [sm])
  }

  it "redirects to the home page if no distributor is selected" do
    get :show
    expect(response).to redirect_to root_path
  end

  describe "with a distributor in place" do
    before do
      allow(controller).to receive(:current_distributor).and_return distributor
    end

    describe "selecting an order cycle" do
      it "should select an order cycle when only one order cycle is open" do
        oc1 = create(:simple_order_cycle, distributors: [distributor])
        get :show
        expect(controller.current_order_cycle).to eq(oc1)
      end

      it "should not set an order cycle when multiple order cycles are open" do
        oc1 = create(:simple_order_cycle, distributors: [distributor])
        oc2 = create(:simple_order_cycle, distributors: [distributor])
        get :show
        expect(controller.current_order_cycle).to be_nil
      end

      it "should allow the user to post to select the current order cycle" do
        oc1 = create(:simple_order_cycle, distributors: [distributor])
        oc2 = create(:simple_order_cycle, distributors: [distributor])

        spree_post :order_cycle, order_cycle_id: oc2.id
        expect(response.status).to eq 200
        expect(controller.current_order_cycle).to eq(oc2)
      end

      context "JSON tests" do
        render_views

        it "should return the order cycle details when the OC is selected" do
          oc1 = create(:simple_order_cycle, distributors: [distributor])
          oc2 = create(:simple_order_cycle, distributors: [distributor])

          spree_post :order_cycle, order_cycle_id: oc2.id
          expect(response.status).to eq 200
          expect(response.body).to have_content oc2.id
        end

        it "should return the current order cycle when hit with GET" do
          oc1 = create(:simple_order_cycle, distributors: [distributor])
          allow(controller).to receive(:current_order_cycle).and_return oc1
          get :order_cycle
          expect(response.body).to have_content oc1.id
        end

        context "when the order cycle has already been set" do
          let(:oc1) { create(:simple_order_cycle, distributors: [distributor]) }
          let(:oc2) { create(:simple_order_cycle, distributors: [distributor]) }
          let(:order) { create(:order, order_cycle: oc1) }

          before { allow(controller).to receive(:current_order) { order } }

          it "returns the new order cycle details" do
            spree_post :order_cycle, order_cycle_id: oc2.id
            expect(response.status).to eq 200
            expect(response.body).to have_content oc2.id
          end
        end
      end

      it "should not allow the user to select an invalid order cycle" do
        oc1 = create(:simple_order_cycle, distributors: [distributor])
        oc2 = create(:simple_order_cycle, distributors: [distributor])
        oc3 = create(:simple_order_cycle, distributors: [create(:distributor_enterprise)])

        spree_post :order_cycle, order_cycle_id: oc3.id
        expect(response.status).to eq(404)
        expect(controller.current_order_cycle).to be_nil
      end
    end
  end
end
