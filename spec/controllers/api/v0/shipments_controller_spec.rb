# frozen_string_literal: true

require 'spec_helper'

describe Api::V0::ShipmentsController, type: :controller do
  render_views

  let!(:shipment) { create(:shipment) }
  let!(:attributes) do
    [:id, :tracking, :number, :cost, :shipped_at, :stock_location_name, :order_id]
  end
  let(:current_api_user) { build(:user) }

  before do
    allow(controller).to receive(:spree_current_user) { current_api_user }
  end

  context "as a non-admin" do
    it "cannot make a shipment ready" do
      api_put :ready, order_id: shipment.order.to_param, id: shipment.to_param
      assert_unauthorized!
    end

    it "cannot make a shipment shipped" do
      api_put :ship, order_id: shipment.order.to_param, id: shipment.to_param
      assert_unauthorized!
    end
  end

  context "as an admin" do
    let(:current_api_user) { build(:admin_user) }
    let!(:order) { shipment.order }
    let(:order_ship_address) { create(:address) }
    let!(:stock_location) { Spree::StockLocation.first || create(:stock_location) }
    let!(:variant) { create(:variant) }
    let(:params) do
      { quantity: 2,
        variant_id: variant.to_param,
        order_id: order.number,
        stock_location_id: stock_location.to_param,
        format: :json }
    end
    let(:error_message) { "broken shipments creation" }

    before do
      order.update_attribute :ship_address_id, order_ship_address.id
      order.update_attribute :distributor, variant.product.supplier
      shipment.shipping_method.distributors << variant.product.supplier
    end

    context '#create' do
      it 'creates a shipment if order does not have a shipment' do
        order.shipment.destroy
        order.reload

        spree_post :create, params

        expect_valid_response
        expect(order.shipment.reload.inventory_units.size).to eq 2
        expect(order.reload.line_items.first.variant.price).to eq(variant.price)
      end

      it 'updates and returns exiting shipment, if order already has a shipment' do
        original_shipment_id = order.shipment.id

        spree_post :create, params

        expect(json_response["id"]).to eq(original_shipment_id)
        expect_valid_response
        expect(order.shipment.reload.inventory_units.size).to eq 2
        expect(order.reload.line_items.first.variant.price).to eq(variant.price)
      end

      it 'updates existing shipment with variant override if an VO is sent' do
        hub = create(:distributor_enterprise)
        order.update_attribute(:distributor, hub)
        shipment.shipping_method.distributors << hub
        variant_override = create(:variant_override, hub: hub, variant: variant)

        spree_post :create, params

        expect_valid_response
        expect(order.shipment.reload.inventory_units.size).to eq 2
        expect(order.reload.line_items.first.price).to eq(variant_override.price)
      end

      it 'returns error code when adding to order contents fails' do
        make_order_contents_fail

        spree_post :create, params

        expect_error_response
      end
    end

    it "can make a shipment ready" do
      allow_any_instance_of(Spree::Order).to receive_messages(paid?: true, complete?: true)
      api_put :ready, order_id: shipment.order.to_param, id: shipment.to_param

      expect(attributes.all?{ |attr| json_response.key? attr.to_s }).to be_truthy
      expect(json_response["state"]).to eq("ready")
      expect(shipment.reload.state).to eq("ready")
    end

    it "cannot make a shipment ready if the order is unpaid" do
      allow_any_instance_of(Spree::Order).to receive_messages(paid?: false)
      api_put :ready, order_id: shipment.order.to_param, id: shipment.to_param

      expect(json_response["error"]).to eq("Cannot ready shipment.")
      expect(response.status).to eq(422)
    end

    describe "#add and #remove" do
      let(:order) { create :completed_order_with_totals }
      let(:line_item) { order.line_items.first }
      let(:existing_variant) { line_item.variant }
      let(:new_variant) { create(:variant) }
      let(:params) {
        {
          quantity: 2,
          order_id: order.to_param,
          id: order.shipments.first.to_param
        }
      }

      before do
        line_item.update!(quantity: 3)
      end

      context 'for completed shipments' do
        it 'adds a variant to a shipment' do
          expect {
            api_put :add, params.merge(variant_id: new_variant.to_param)
            expect(response.status).to eq(200)
          }.to change { inventory_units_for(new_variant).size }.by(2)
        end

        it 'adjusts stock when adding a variant' do
          expect {
            api_put :add, params.merge(variant_id: new_variant.to_param)
          }.to change { new_variant.reload.on_hand }.by(-2)
        end

        it 'removes a variant from a shipment' do
          expect {
            api_put :remove, params.merge(variant_id: existing_variant.to_param)
            expect(response.status).to eq(200)
          }.to change { inventory_units_for(existing_variant).size }.by(-2)
        end

        it 'adjusts stock when removing a variant' do
          expect {
            api_put :remove, params.merge(variant_id: existing_variant.to_param)
          }.to change { existing_variant.reload.on_hand }.by(2)
        end

        it 'does not adjust stock when removing a variant' do
          expect {
            api_put :remove, params.merge(variant_id: existing_variant.to_param,
                                          restock_item: 'false')
          }.to change { existing_variant.reload.on_hand }.by(0)
        end
      end

      context "for canceled orders" do
        before do
          expect(order.cancel).to eq true
        end

        it "doesn't adjust stock when adding a variant" do
          expect {
            api_put :add, params.merge(variant_id: existing_variant.to_param)
            expect(response.status).to eq(422)
          }.to_not change { existing_variant.reload.on_hand }
        end

        it "doesn't adjust stock when removing a variant" do
          expect {
            api_put :remove, params.merge(variant_id: existing_variant.to_param)
            expect(response.status).to eq(422)
          }.to_not change { existing_variant.reload.on_hand }
        end
      end

      context "with shipping fees" do
        let!(:distributor) { create(:distributor_enterprise) }
        let(:fee_amount) { 10 }
        let!(:shipping_method_with_fee) {
          create(:shipping_method_with, :shipping_fee, distributors: [distributor],
                                                       shipping_fee: fee_amount)
        }
        let!(:order_cycle) { create(:order_cycle, distributors: [distributor]) }
        let!(:order) {
          create(:completed_order_with_totals, order_cycle: order_cycle, distributor: distributor)
        }
        let(:shipping_fee) { order.reload.shipment.adjustments.first }

        before do
          order.shipments.first.shipping_methods = [shipping_method_with_fee]
          order.select_shipping_method(shipping_method_with_fee.id)
          order.update_order!
        end

        context "adding item to a shipment" do
          it "updates the shipping fee" do
            expect {
              api_put :add, params.merge(variant_id: new_variant.to_param)
            }.to change { order.reload.shipment.adjustments.first.amount }.by(20)
          end
        end

        context "removing item from a shipment" do
          it "updates the shipping fee" do
            expect {
              api_put :remove, params.merge(variant_id: existing_variant.to_param)
            }.to change { order.reload.shipment.adjustments.first.amount }.by(-20)
          end
        end
      end
    end

    describe "#update" do
      let!(:distributor) { create(:distributor_enterprise) }
      let!(:shipping_method1) {
        create(:shipping_method_with, :flat_rate, distributors: [distributor], amount: 10)
      }
      let!(:shipping_method2) {
        create(:shipping_method_with, :flat_rate, distributors: [distributor], amount: 20)
      }
      let!(:order_cycle) { create(:order_cycle, distributors: [distributor]) }
      let!(:order) {
        create(:completed_order_with_totals, order_cycle: order_cycle, distributor: distributor)
      }
      let(:new_shipping_rate) {
        order.shipment.shipping_rates.select{ |sr| sr.shipping_method == shipping_method2 }.first
      }
      let(:params) {
        {
          id: order.shipment.number,
          order_id: order.number,
          shipment: {
            selected_shipping_rate_id: new_shipping_rate.id
          }
        }
      }

      before do
        order.shipments.first.shipping_methods = [shipping_method1, shipping_method2]
        order.shipments.each(&:refresh_rates)
        order.select_shipping_method(shipping_method1.id)
        order.update_order!
        order.update_columns(
          payment_total: 60,
          payment_state: "paid"
        )
      end

      context "when an order has multiple shipping methods available which could be chosen" do
        context "changing the selected shipping method" do
          it "updates the order's totals and states" do
            expect(order.shipment.shipping_method).to eq shipping_method1
            expect(order.shipment.cost).to eq 10
            expect(order.total).to eq 60 # item total is 50, shipping cost is 10
            expect(order.payment_state).to eq "paid" # order is fully paid for

            api_put :update, params
            expect(response.status).to eq 200

            order.reload

            expect(order.shipment.shipping_method).to eq shipping_method2
            expect(order.shipment.cost).to eq 20
            expect(order.total).to eq 70 # item total is 50, shipping cost is 20
            expect(order.payment_state).to eq "balance_due" # total changed, payment is due
          end

          it "updates closed adjustments" do
            expect {
              api_put :update, params
              expect(response.status).to eq 200
            }.to change { order.reload.shipment.fee_adjustment.amount }
          end
        end
      end
    end

    context "#ship" do
      before do
        allow_any_instance_of(Spree::Order).to receive_messages(paid?: true, complete?: true)
        # For the shipment notification email
        Spree::Config[:mails_from] = "ofn@example.com"

        shipment.update!(shipment.order)
        expect(shipment.state).to eq("ready")
        allow_any_instance_of(Spree::ShippingRate).to receive_messages(cost: 5)
      end

      it "can transition a shipment from ready to ship" do
        shipment.reload
        api_put :ship, order_id: shipment.order.to_param,
                       id: shipment.to_param,
                       shipment: { tracking: "123123" }

        expect(attributes.all?{ |attr| json_response.key? attr.to_s }).to be_truthy
        expect(json_response["state"]).to eq("shipped")
      end
    end

    context 'for a completed order with shipment' do
      let(:order) { create :completed_order_with_totals }

      before { params[:id] = order.shipments.first.to_param }

      context '#add' do
        it 'adds a variant to the shipment' do
          spree_put :add, params

          expect_valid_response
          expect(inventory_units_for(variant).size).to eq 2
        end

        it 'returns error code when adding to order contents fails' do
          make_order_contents_fail

          spree_put :add, params

          expect_error_response
        end

        it 'adds a variant override to the shipment' do
          hub = create(:distributor_enterprise)
          order.update_attribute(:distributor, hub)
          variant_override = create(:variant_override, hub: hub, variant: variant)

          spree_put :add, params

          expect_valid_response
          expect(inventory_units_for(variant).size).to eq 2
          expect(order.reload.line_items.last.price).to eq(variant_override.price)
        end

        context "when line items have fees" do
          let(:fee_order) {
            instance_double(Spree::Order, number: "123", distributor: variant.product.supplier)
          }
          let(:contents) { instance_double(Spree::OrderContents) }

          before do
            allow(Spree::Order).to receive(:find_by!) { fee_order }
            allow(controller).to receive(:find_and_update_shipment) {}
            allow(controller).to receive(:refuse_changing_cancelled_orders) {}
            allow(fee_order).to receive(:contents) { contents }
            allow(contents).to receive(:add) {}
            allow(fee_order).to receive(:recreate_all_fees!)
          end

          it "recalculates fees for the line item" do
            params[:order_id] = fee_order.number
            spree_put :add, params
            expect(fee_order).to have_received(:recreate_all_fees!)
          end
        end
      end

      context '#remove' do
        before do
          params[:variant_id] = order.line_items.first.variant.to_param
          params[:quantity] = 1
        end

        it 'removes a variant from the shipment' do
          spree_put :remove, params

          expect_valid_response
          expect(inventory_units_for(variant).size).to eq 0
        end

        it 'returns error code when removing from order contents fails' do
          make_order_contents_fail

          spree_put :remove, params

          expect_error_response
        end
      end
    end

    def inventory_units_for(variant)
      order.shipment.reload.inventory_units.select { |unit| unit['variant_id'] == variant.id }
    end

    def expect_valid_response
      expect(response.status).to eq 200
      attributes.all?{ |attr| json_response.key? attr.to_s }
    end

    def make_order_contents_fail
      expect(Spree::Order).to receive(:find_by!).with({ number: order.number }) { order }
      expect(order).to receive(:contents) { raise error_message }
    end

    def expect_error_response
      expect(response.status).to eq 422
      expect(json_response["exception"]).to eq error_message
    end
  end
end
