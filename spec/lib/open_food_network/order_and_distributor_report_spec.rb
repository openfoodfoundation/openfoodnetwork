require 'spec_helper'

module OpenFoodNetwork
  describe OrderAndDistributorReport do
    describe 'orders and distributors report' do
      it 'should return a header row describing the report' do
        subject = OrderAndDistributorReport.new nil

        header = subject.header
        expect(header).to eq(['Order date', 'Order Id',
                              'Customer Name', 'Customer Email', 'Customer Phone', 'Customer City',
                              'SKU', 'Item name', 'Variant', 'Quantity', 'Max Quantity', 'Cost', 'Shipping Cost',
                              'Payment Method',
                              'Distributor', 'Distributor address', 'Distributor city', 'Distributor postcode', 'Shipping instructions'])
      end

      context 'with completed order' do
        let(:bill_address) { create(:address) }
        let(:distributor) { create(:distributor_enterprise) }
        let(:product) { create(:product) }
        let(:shipping_instructions) { 'pick up on thursday please!' }
        let(:order) { create(:order, state: 'complete', completed_at: Time.zone.now, distributor: distributor, bill_address: bill_address, special_instructions: shipping_instructions) }
        let(:payment_method) { create(:payment_method, distributors: [distributor]) }
        let(:payment) { create(:payment, payment_method: payment_method, order: order) }
        let(:line_item) { create(:line_item, product: product, order: order) }

        before do
          order.payments << payment
          order.line_items << line_item
        end

        it 'should denormalise order and distributor details for display as csv' do
          subject = OrderAndDistributorReport.new create(:admin_user), {}, true

          table = subject.table

          expect(table[0]).to eq([
            order.reload.created_at,
            order.id,
            bill_address.full_name,
            order.email,
            bill_address.phone,
            bill_address.city,
            line_item.product.sku,
            line_item.product.name,
            line_item.options_text,
            line_item.quantity,
            line_item.max_quantity,
            line_item.price * line_item.quantity,
            line_item.distribution_fee,
            payment_method.name,
            distributor.name,
            distributor.address.address1,
            distributor.address.city,
            distributor.address.zipcode,
            shipping_instructions
          ])
        end
      end
    end
  end
end
