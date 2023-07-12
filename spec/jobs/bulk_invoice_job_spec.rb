# frozen_string_literal: true

require 'spec_helper'

describe BulkInvoiceJob do
  subject { BulkInvoiceJob.new(order_ids, "/tmp/file/path") }

  describe "#sorted_orders" do
    let(:order1) { build(:order, id: 1) }
    let(:order2) { build(:order, id: 2) }
    let(:order3) { build(:order, id: 3) }
    let(:order_ids) { [3, 1, 2] }

    it "returns results in their original order" do
      expect(Spree::Order).to receive(:where).and_return([order1, order2, order3])

      expect(subject.__send__(:sorted_orders, order_ids)).to eq [order3, order1, order2]
    end
  end

  context "when invoices are enabled" do
    before do
      Flipper.enable(:invoices)
    end

    describe "#perform" do
      let(:order1) { create(:order) }
      let(:order2) { create(:order) }
      let(:order3) { create(:order) }
      let(:order_ids) { [order1.id, order2.id, order3.id] }
      it "should generate invoices for invoiceable orders only" do
        expect(subject).to receive(:sorted_orders).with(order_ids).and_return([order1, order2,
                                                                               order3])
        expect(order1).to receive(:invoiceable?).and_return(true)
        expect(order2).to receive(:invoiceable?).and_return(false)
        expect(order3).to receive(:invoiceable?).and_return(true)

        [order1, order3].each do |order|
          expect(subject).to receive(:generate_invoice).with(order)
        end
        expect(subject).not_to receive(:generate_invoice).with(order2)

        subject.perform(order_ids, "/tmp/file/path")
      end
    end

    describe "#generate_invoice" do
      let(:order) { create(:completed_order_with_totals) }
      let(:order_ids){ [order.id] }
      let!(:invoice_data_generator){ InvoiceDataGenerator.new(order) }
      let!(:invoice){
        create(:invoice, order:,
                         data: invoice_data_generator.serialize_for_invoice)
      }
      let(:generator){ double("generator") }
      let(:renderer){ double("renderer") }
      let(:printed_invoice_string){ "printed invoice string" }

      before do
        expect(OrderInvoiceGenerator).to receive(:new).with(order).and_return(generator)
        expect(subject).to receive(:renderer).and_return(renderer)
      end

      it "should call the renderer with the invoice presenter" do
        expect(generator).to receive(:generate_or_update_latest_invoice)
        expect(renderer).to receive(:render_to_string).with(invoice.presenter)
          .and_return(printed_invoice_string)
        expect(order).to receive(:invoices).and_return([invoice])
        expect(CombinePDF).to receive(:parse).with(printed_invoice_string)

        subject.__send__(:generate_invoice, order)
      end
    end
  end
end
