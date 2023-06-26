# frozen_string_literal: true

require 'spec_helper'

describe OrderShipment do
  let(:order) { create(:order) }

  describe "#shipping_method" do
    context "when order has no shipments" do
      it "returns nil" do
        expect(order.shipping_method).to be_nil
      end
    end

    context "when order has single shipment" do
      it "returns the shipments shipping_method" do
        shipping_method = create(:shipping_method_with, :flat_rate)
        shipment = create(:shipment_with, :shipping_method, shipping_method: shipping_method)
        order.shipments = [shipment]

        expect(order.shipping_method).to eq shipment.shipping_method
      end
    end
  end

  describe "#select_shipping_method" do
    let(:shipping_method) { create(:shipping_method_with, :flat_rate) }

    context "when order has no shipment" do
      it "returns nil" do
        expect(order.select_shipping_method(shipping_method.id)).to be_nil
      end
    end

    context "when order has a shipment" do
      let(:shipment) { create(:shipment_with, :shipping_method, shipping_method: shipping_method) }
      before { order.shipments = [shipment] }

      context "when no shipping_method_id is provided" do
        it "returns nil for nil shipping_method_id" do
          expect(order.select_shipping_method(nil)).to be_nil
        end

        it "returns nil for empty shipping_method_id" do
          empty_shipping_method_id = ' '
          expect(shipment.shipping_rates).to_not receive(:find_by)
            .with(shipping_method_id: empty_shipping_method_id)

          expect(order.select_shipping_method(empty_shipping_method_id)).to be_nil
        end
      end

      context "when shipping_method_id is not valid for the order" do
        it "returns nil" do
          invalid_shipping_method_id = order.shipment.shipping_method.id + 1000
          expect(shipment.shipping_rates).to receive(:find_by)
            .with(shipping_method_id: invalid_shipping_method_id) { nil }

          expect(order.select_shipping_method(invalid_shipping_method_id)).to be_nil
        end
      end

      context "when shipping_method_id is valid for the order" do
        it "returns the shipments shipping_method" do
          expect(shipment).to receive(:selected_shipping_rate_id=)

          expect(order.select_shipping_method(shipping_method.id)).to eq shipping_method
        end
      end

      context "when multiple shipping_methods exist in the shipment" do
        let(:expensive_shipping_method) { create(:shipping_method_with, :expensive_name) }
        before { shipment.add_shipping_method(expensive_shipping_method, false ) }

        it "selects a shipping method that was not selected by default " \
           "and persists the selection in the database" do
          expect(shipment.shipping_method).to eq shipping_method

          expect(order.select_shipping_method(expensive_shipping_method.id))
            .to eq expensive_shipping_method

          expect(shipment.shipping_method).to eq expensive_shipping_method

          shipment.reload

          expect(shipment.shipping_method).to eq expensive_shipping_method
        end
      end
    end
  end
end
