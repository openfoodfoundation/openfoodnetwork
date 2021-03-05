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

        expect(json_response["id"]). to eq(original_shipment_id)
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

    context 'for completed shipments' do
      let(:order) { create :completed_order_with_totals }

      it 'adds a variant to a shipment' do
        api_put :add, variant_id: variant.to_param,
                      quantity: 2,
                      order_id: order.to_param,
                      id: order.shipments.first.to_param

        expect(response.status).to eq(200)
        expect(inventory_units_for(variant).size).to eq 2
      end

      it 'removes a variant from a shipment' do
        order.contents.add(variant, 2)
        api_put :remove, variant_id: variant.to_param,
                         quantity: 1,
                         order_id: order.to_param,
                         id: order.shipments.first.to_param

        expect(response.status).to eq(200)
        expect(inventory_units_for(variant).size).to eq(1)
      end
    end

    context "can transition a shipment from ready to ship" do
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
