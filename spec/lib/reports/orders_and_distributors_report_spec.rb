# frozen_string_literal: true

require 'spec_helper'

module Reporting
  module Reports
    module OrdersAndDistributors
      describe Base do
        describe 'orders and distributors report' do
          it 'should return a header row describing the report' do
            subject = Base.new nil

            expect(subject.table_headers).to eq(
              [
                'Order date', 'Order Id',
                'Customer Name', 'Customer Email', 'Customer Phone', 'Customer City',
                'SKU', 'Item name', 'Variant', 'Quantity', 'Max Quantity', 'Cost', 'Shipping Cost',
                'Payment Method',
                'Distributor', 'Distributor address', 'Distributor city', 'Distributor postcode',
                'Shipping Method', 'Shipping instructions'
              ]
            )
          end

          context 'with completed order' do
            let(:bill_address) { create(:address) }
            let(:distributor) { create(:distributor_enterprise) }
            let(:distributor1) { create(:distributor_enterprise) }
            let(:product) { create(:product) }
            let(:shipping_method) { create(:shipping_method) }
            let(:shipping_instructions) { 'pick up on thursday please!' }
            let(:order) {
              create(:order,
                     state: 'complete', completed_at: Time.zone.now,
                     distributor: distributor, bill_address: bill_address,
                     special_instructions: shipping_instructions)
            }
            let(:payment_method) { create(:payment_method, distributors: [distributor]) }
            let(:payment) { create(:payment, payment_method: payment_method, order: order) }
            let(:line_item) { create(:line_item_with_shipment, product: product, order: order) }

            before do
              order.select_shipping_method(shipping_method.id)
              order.payments << payment
              order.line_items << line_item
            end

            it 'should denormalise order and distributor details for display as csv' do
              subject = Base.new create(:admin_user), {}
              allow(subject).to receive(:unformatted_render?).and_return(true)
              table = subject.table_rows

              expect(table.size).to eq 1
              expect(table[0]).to eq([
                                       order.reload.completed_at.strftime("%F %T"),
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
                                       shipping_method.name,
                                       shipping_instructions
                                     ])
            end

            it "prints one row per line item" do
              create(:line_item_with_shipment, order: order)

              subject = Base.new(create(:admin_user))

              table = subject.table_rows
              expect(table.size).to eq 2
            end

            context "filtering by distributor" do
              it do
                create(:line_item_with_shipment, order: order)

                report1 = Base.new(create(:admin_user), {})
                table = report1.table_rows
                expect(table.size).to eq 2

                report2 = Base.new(create(:admin_user),
                                   { q: { distributor_id_in: [distributor.id] } })
                table2 = report2.table_rows
                expect(table2.size).to eq 2

                report3 = Base.new(create(:admin_user),
                                   { q: { distributor_id_in: [distributor1.id] } })
                table3 = report3.table_rows
                expect(table3.size).to eq 0
              end
            end
          end
        end
      end
    end
  end
end
