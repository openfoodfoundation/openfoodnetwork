# frozen_string_literal: true

require 'spec_helper'

module Spree
  describe Calculator do
    let(:calculator) { Spree::Calculator.new }
    let!(:enterprise) { create(:enterprise) }
    let!(:order) { create(:order) }
    let!(:shipment) { create(:shipment) }
    let!(:line_item) { create(:line_item, order: order) }
    let!(:line_item2) { create(:line_item, order: order) }

    before do
      order.reload.shipments = [shipment]
    end

    describe "#line_items_for" do
      it "returns the line item if given a line item" do
        result = calculator.__send__(:line_items_for, line_item)

        expect(result).to eq [line_item]
      end

      it "returns line items if given an object with line items" do
        result = calculator.__send__(:line_items_for, order)

        expect(result).to eq [line_item, line_item2]
      end

      it "returns line items if given an object with an order" do
        result = calculator.__send__(:line_items_for, shipment)

        expect(result).to eq [line_item, line_item2]
      end

      it "returns the original object if given anything else" do
        result = calculator.__send__(:line_items_for, enterprise)

        expect(result).to eq [enterprise]
      end
    end
  end
end
