# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe OrderBuilder do
  describe ".new_order" do
    subject(:result) { described_class.new_order(ofn_order) }
    let(:ofn_order) {
      create(
        :completed_order_with_totals,
        id: 1,
      )
    }

    it "builds a new order" do
      expect(result.semanticId).to eq nil
      expect(result.lines.count).to eq 0
      expect(result.orderStatus).to eq "dfc-v:Held"
    end
  end
end
