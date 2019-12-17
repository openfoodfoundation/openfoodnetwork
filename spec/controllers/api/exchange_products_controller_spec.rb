require 'spec_helper'

module Api
  describe ExchangeProductsController, type: :controller do
    include AuthenticationWorkflow

    let!(:order_cycle) { create(:order_cycle) }
    let!(:coordinator) { order_cycle.coordinator }

    before do
      allow(controller).to receive_messages spree_current_user: coordinator.owner
    end

    describe "#index" do
      describe "for incoming exchanges" do
        it "loads data" do
          exchange = order_cycle.exchanges.incoming.first
          spree_get :index, exchange_id: exchange.id

          expect(json_response.first["supplier_name"]).to eq exchange.variants.first.product.supplier.name
        end
      end

      describe "for outgoing exchanges" do
        it "loads data" do
          exchange = order_cycle.exchanges.outgoing.first
          spree_get :index, exchange_id: exchange.id

          suppliers = [exchange.variants[0].product.supplier.name, exchange.variants[1].product.supplier.name]
          expect(suppliers).to include json_response.first["supplier_name"]
          expect(suppliers).to include json_response.second["supplier_name"]
        end
      end
    end
  end
end
