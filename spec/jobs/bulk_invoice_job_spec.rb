# frozen_string_literal: true

require 'spec_helper'

describe BulkInvoiceJob do
  let(:order1) { build(:order, id: 1) }
  let(:order2) { build(:order, id: 2) }
  let(:order3) { build(:order, id: 3) }

  let(:order_ids) { [3, 1, 2] }

  subject { BulkInvoiceJob.new(order_ids, "/tmp/file/path") }

  describe "#sorted_orders" do
    it "returns results in their original order" do
      expect(Spree::Order).to receive(:where).and_return([order1, order2, order3])

      expect(subject.__send__(:sorted_orders, order_ids)).to eq [order3, order1, order2]
    end
  end
end
