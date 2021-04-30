# frozen_string_literal: true

require 'spec_helper'

module OrderManagement
  module Stock
    describe Package do
      context "base tests" do
        let(:variant) { build(:variant, weight: 25.0) }
        let(:stock_location) { build(:stock_location) }
        let(:distributor) { create(:enterprise) }
        let(:order) { build(:order, distributor: distributor) }

        subject { Package.new(stock_location, order) }

        it 'calculates the weight of all the contents' do
          subject.add variant, 4
          expect(subject.weight).to eq 100.0
        end

        it 'filters by on_hand and backordered' do
          subject.add variant, 4, :on_hand
          subject.add variant, 3, :backordered
          expect(subject.on_hand.count).to eq 1
          expect(subject.backordered.count).to eq 1
        end

        it 'calculates the quantity by state' do
          subject.add variant, 4, :on_hand
          subject.add variant, 3, :backordered

          expect(subject.quantity).to eq 7
          expect(subject.quantity(:on_hand)).to eq 4
          expect(subject.quantity(:backordered)).to eq 3
        end

        it 'returns nil for content item not found' do
          item = subject.find_item(variant, :on_hand)
          expect(item).to be_nil
        end

        it 'finds content item for a variant' do
          subject.add variant, 4, :on_hand
          item = subject.find_item(variant, :on_hand)
          expect(item.quantity).to eq 4
        end

        it 'get flattened contents' do
          subject.add variant, 4, :on_hand
          subject.add variant, 2, :backordered
          flattened = subject.flattened
          expect(flattened.select { |i| i.state == :on_hand }.size).to eq 4
          expect(flattened.select { |i| i.state == :backordered }.size).to eq 2
        end

        it 'set contents from flattened' do
          flattened = [Package::ContentItem.new(variant, 1, :on_hand),
                       Package::ContentItem.new(variant, 1, :on_hand),
                       Package::ContentItem.new(variant, 1, :backordered),
                       Package::ContentItem.new(variant, 1, :backordered)]

          subject.flattened = flattened
          expect(subject.on_hand.size).to eq 1
          expect(subject.on_hand.first.quantity).to eq 2

          expect(subject.backordered.size).to eq 1
        end

        # Contains regression test for #2804
        it 'builds a list of shipping methods from all categories' do
          shipping_method1 = create(:shipping_method, distributors: [distributor])
          shipping_method2 = create(:shipping_method, distributors: [distributor])
          variant1 = create(:variant,
                            shipping_category: shipping_method1.shipping_categories.first)
          variant2 = create(:variant,
                            shipping_category: shipping_method2.shipping_categories.first)
          variant3 = create(:variant, shipping_category: nil)
          contents = [Package::ContentItem.new(variant1, 1),
                      Package::ContentItem.new(variant1, 1),
                      Package::ContentItem.new(variant2, 1),
                      Package::ContentItem.new(variant3, 1)]

          package = Package.new(stock_location, order, contents)
          expect(package.shipping_methods.size).to eq 2
        end

        it "can convert to a shipment" do
          flattened = [Package::ContentItem.new(variant, 2, :on_hand),
                       Package::ContentItem.new(variant, 1, :backordered)]
          subject.flattened = flattened

          shipping_method = build(:shipping_method)
          subject.shipping_rates = [
            Spree::ShippingRate.new(shipping_method: shipping_method, cost: 10.00, selected: true)
          ]

          shipment = subject.to_shipment
          expect(shipment.order).to eq subject.order
          expect(shipment.stock_location).to eq subject.stock_location
          expect(shipment.inventory_units.size).to eq 3

          first_unit = shipment.inventory_units.first
          expect(first_unit.variant).to eq variant
          expect(first_unit.state).to eq 'on_hand'
          expect(first_unit.order).to eq subject.order
          expect(first_unit).to be_pending

          last_unit = shipment.inventory_units.last
          expect(last_unit.variant).to eq variant
          expect(last_unit.state).to eq 'backordered'
          expect(last_unit.order).to eq subject.order

          expect(shipment.shipping_method).to eq shipping_method
        end

        describe "#inpsect" do
          it "prints the package contents" do
            subject.add variant, 5
            expect(subject.inspect).to match("#{variant.name} 5")
          end
        end
      end

      context "#shipping_methods and #shipping_categories" do
        let(:stock_location) { double(:stock_location) }

        subject(:package) { Package.new(stock_location, order, contents) }

        let(:enterprise) { create(:enterprise) }
        let(:other_enterprise) { create(:enterprise) }

        let(:order) { build(:order, distributor: enterprise) }

        let(:variant1) do
          instance_double(
            Spree::Variant,
            shipping_category: shipping_method1.shipping_categories.first
          )
        end
        let(:variant2) do
          instance_double(
            Spree::Variant,
            shipping_category: shipping_method2.shipping_categories.first
          )
        end
        let(:variant3) do
          instance_double(Spree::Variant, shipping_category: nil)
        end

        let(:contents) do
          [
            Package::ContentItem.new(variant1, 1),
            Package::ContentItem.new(variant1, 1),
            Package::ContentItem.new(variant2, 1),
            Package::ContentItem.new(variant3, 1)
          ]
        end

        let(:shipping_method1) { create(:shipping_method, distributors: [enterprise]) }
        let(:shipping_method2) { create(:shipping_method, distributors: [other_enterprise]) }
        let!(:shipping_method3) {
          create(:shipping_method, distributors: [enterprise], deleted_at: Time.zone.now)
        }

        describe "#shipping_methods" do
          it "does not return shipping methods not used by the package's order distributor" do
            expect(package.shipping_methods).to eq [shipping_method1]
          end

          it "does not return soft-deleted shipping methods" do
            expect(package.shipping_methods).to_not include shipping_method3
          end

          it "returns an empty array if distributor is nil" do
            allow(order).to receive(:distributor) { nil }

            expect(package.shipping_methods).to eq []
          end
        end
      end
    end
  end
end
