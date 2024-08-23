# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FdcBackorderer do
  let(:order) { create(:completed_order_with_totals) }

  describe "#find_or_build_order" do
    it "builds an order object" do
      backorder = subject.find_or_build_order(order)

      expect(backorder.semanticId).to match %r{^https.*/\#$}
      expect(backorder.lines).to eq []
    end
  end
end
