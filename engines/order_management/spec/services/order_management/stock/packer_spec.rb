# frozen_string_literal: true

require 'spec_helper'

module OrderManagement
  module Stock
    RSpec.describe Packer do
      let(:distributor) { create(:distributor_enterprise) }
      let(:order) { create(:order_with_line_items, line_items_count: 5, distributor:) }

      subject { Packer.new(order) }

      before { order.line_items.first.variant.update(unit_value: 100) }

      it 'builds a package with all the items' do
        package = subject.package

        expect(package.contents.size).to eq 5
        expect(package.weight).to be_positive
      end

      it 'variants are added as backordered without enough on_hand' do
        order.line_items.each do |item|
          expect(item.variant).to receive(:fill_status).and_return([2, 3])
        end

        package = subject.package
        expect(package.on_hand.size).to eq 5
        expect(package.backordered.size).to eq 5
      end

      it "accounts for variant overrides", feature: :inventory do
        variant = order.line_items.first.variant
        variant.on_hand = 0
        variant.on_demand = false
        variant.save
        expect {
          create(:variant_override, variant:, hub: distributor, count_on_hand: 10)
        }.to change {
          subject.package.on_hand.size
        }.from(4).to(5)
      end
    end
  end
end
