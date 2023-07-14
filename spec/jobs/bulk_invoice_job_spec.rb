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
      let!(:order1) { create(:shipped_order) }
      let!(:order2) { create(:order_with_line_items) }
      let!(:order3) { create(:order_ready_to_ship) }
      let(:order_ids) { [order1.id, order2.id, order3.id] }
      let(:path){ "/tmp/file/path.pdf" }
      before do
        order3.cancel
        order3.resume
      end
      it "should generate invoices for invoiceable orders only" do
        expect{
          subject.perform(order_ids, path)
        }.to change{ order1.invoices.count }.from(0).to(1)
          .and change{ order2.invoices.count }.by(0)
          .and change{ order3.invoices.count }.from(0).to(1)

        File.open(path, "rb") do |io|
          reader = PDF::Reader.new(io)
          content = reader.pages.map(&:text).join("\n")
          expect(content).to include(order1.number)
          expect(content).to include(order3.number)
          expect(content).not_to include(order2.number)
        end
      end
    end
  end
end
