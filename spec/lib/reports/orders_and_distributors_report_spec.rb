# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Reporting::Reports::OrdersAndDistributors::Base do
  describe 'orders and distributors report' do
    subject { described_class.new nil }

    it 'should return a header row describing the report' do
      expect(subject.table_headers).to eq(
        [
          'Order date', 'Order Id',
          'Customer Name', 'Customer Email', 'Customer Phone', 'Customer City',
          'SKU', 'Product', 'Variant', 'Quantity', 'Max Quantity', 'Cost', 'Shipping Cost',
          'Payment Method',
          'Distributor', 'Distributor address', 'Distributor city', 'Distributor postcode',
          'Shipping Method', 'Shipping instructions'
        ]
      )
    end

    context 'as a supplier, with completed order' do
      let(:bill_address) { create(:address) }
      let(:distributor) { create(:distributor_enterprise) }
      let(:distributor1) { create(:distributor_enterprise) }
      let(:supplier) { create(:supplier_enterprise) }
      let(:user) { create(:admin_user) }
      let(:product) { variant.product }
      let(:variant) { create(:variant, supplier:) }
      let(:shipping_method) { create(:shipping_method) }
      let(:shipping_instructions) { 'pick up on thursday please!' }
      let(:order) {
        create(:order,
               state: 'complete', completed_at: Time.zone.now,
               distributor:, bill_address:,
               special_instructions: shipping_instructions)
      }
      let(:payment_method) { create(:payment_method, distributors: [distributor]) }
      let(:payment) { create(:payment, payment_method:, order:) }
      let(:line_item) { create(:line_item_with_shipment, variant:, order:) }
      subject { described_class.new user }

      before do
        order.select_shipping_method(shipping_method.id)
        order.payments << payment
        order.line_items << line_item
      end

      context "without variant name" do
        it 'should denormalise order and distributor details for display as csv' do
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
                                   "1g",
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
      end

      it "prints one row per line item" do
        create(:line_item_with_shipment, order:)

        table = subject.table_rows
        expect(table.size).to eq 2
      end

      context "filtering by distributor" do
        it do
          create(:line_item_with_shipment, order:)

          report1 = described_class.new(create(:admin_user), {})
          table = report1.table_rows
          expect(table.size).to eq 2

          report2 = described_class.new(create(:admin_user),
                                        { q: { distributor_id_in: [distributor.id] } })
          table2 = report2.table_rows
          expect(table2.size).to eq 2

          report3 = described_class.new(create(:admin_user),
                                        { q: { distributor_id_in: [distributor1.id] } })
          table3 = report3.table_rows
          expect(table3.size).to eq 0
        end
      end

      context "as a supplier, who has granted P-OC to the distributor" do
        let(:user) { create(:enterprise_user, enterprises: [supplier]) }
        let(:bill_address) {
          create(:address, first_name: "FirstName", last_name: "LastName", phone: "123-456",
                           city: "City")
        }
        let(:row) { subject.table_rows.first }

        before do
          create(:enterprise_relationship, parent: supplier, child: distributor,
                                           permissions_list: [:add_to_order_cycle])
        end

        it "shows line items supplied by my producers, with contact details hidden" do
          expect(row).not_to include("FirstName LastName")
          expect(row).not_to include("123-456", "City", order.email)
          expect(row[2..5]).to eq ["HIDDEN", "HIDDEN", "", ""]
        end

        context "where the distributor allows suppliers to see customer names" do
          before do
            distributor.update_columns show_customer_names_to_suppliers: true
          end

          it "shows line items supplied by my producers, with only contact names shown" do
            expect(row).to include("FirstName LastName")
            expect(row).not_to include("123-456", "City", order.email)
            expect(row[2..5]).to eq [bill_address.full_name, "HIDDEN", "", ""]
          end
        end
      end

      it "minimises database queries" do
        subject # build context first

        expect { subject.table_rows }.to query_database [
          "Spree::Role Exists?",
          "Spree::Role Exists?",
          "SQL",
          "Spree::LineItem Load",
          "Spree::PaymentMethod Load",
          "Spree::Calculator Load",
          "Spree::Shipment Load",
          "Spree::ShippingRate Load",
          "Spree::ShippingMethod Load",
        ]
      end

      context "with variant name present" do
        before do
          variant.update_columns(display_name: 'Variant Name');
        end
        let(:row) { subject.table_rows.first }

        it "should display variant name with unit" do
          expect(row).to include("Variant Name (1g)")
        end
      end
    end
  end
end
