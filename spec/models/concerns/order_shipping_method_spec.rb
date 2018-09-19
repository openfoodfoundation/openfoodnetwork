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
        shipment = create(:shipment_with_flat_rate)
        order.shipments = [shipment]

        expect(order.shipping_method).to eq shipment.shipping_method
      end
    end
  end
end
