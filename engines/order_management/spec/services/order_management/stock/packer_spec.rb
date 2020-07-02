# frozen_string_literal: true

require 'spec_helper'

module OrderManagement
  module Stock
    describe Packer do
      let(:order) { create(:order_with_line_items, line_items_count: 5) }
      let(:stock_location) { create(:stock_location) }

      subject { Packer.new(stock_location, order) }

      context 'packages' do
        it 'builds an array of packages' do
          packages = subject.packages
          expect(packages.size).to eq 1
          expect(packages.first.contents.size).to eq 5
        end
      end

      context 'default_package' do
        before { order.line_items.first.variant.update(weight: 1) }

        it 'contains all the items' do
          package = subject.default_package
          expect(package.contents.size).to eq 5
          expect(package.weight).to be_positive
        end

        it 'variants are added as backordered without enough on_hand' do
          expect(stock_location).to receive(:fill_status).exactly(5).times.and_return([2, 3])

          package = subject.default_package
          expect(package.on_hand.size).to eq 5
          expect(package.backordered.size).to eq 5
        end
      end
    end
  end
end
