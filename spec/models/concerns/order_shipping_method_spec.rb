require 'spec_helper'

describe OrderShippingMethod do
  let(:order) { create(:order) }

  describe '#shipping_method' do
    context 'when order has no shipments' do
      it 'returns nil' do
        expect(order.shipping_method).to be_nil
      end
    end

    context 'when order has single shipment' do
      it 'returns the shipments shipping_method' do
        shipping_method = create(:shipping_method_with, :flat_rate)
        shipment = create(:shipment_with, :shipping_method, shipping_method: shipping_method)
        order.shipments = [shipment]

        expect(order.shipping_method).to eq shipment.shipping_method
      end
    end
  end
end
