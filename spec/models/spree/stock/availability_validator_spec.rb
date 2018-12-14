require 'spec_helper'

module Spree
  module Stock
    describe AvailabilityValidator do
      let(:validator) { AvailabilityValidator.new({}) }

      context "line item without existing inventory units" do
        let(:order) { create(:order_with_line_items) }
        let(:line_item) { order.line_items.first }

        before do
          expect(order.shipment.inventory_units).to be_empty
          expect(line_item.target_shipment).to be_nil
        end

        context "available quantity when variant.on_hand > line_item.quantity" do
          it "suceeds" do
            line_item.quantity = line_item.variant.on_hand - 1
            validator.validate(line_item)
            expect(line_item.errors[:quantity].size).to eq(0)
          end
        end

        context "unavailable quantity when variant.on_hand < line_item.quantity" do
          it "fails" do
            line_item.quantity = line_item.variant.on_hand + 1
            validator.validate(line_item)
            expect_product_out_of_stock_error
          end

          it "succeeds with line_item skip_stock_check" do
            line_item.skip_stock_check = true
            line_item.quantity = line_item.variant.on_hand + 1
            validator.validate(line_item)
            expect(line_item.errors[:quantity].size).to eq(0)
          end
        end
      end

      describe "line item with existing inventory units" do
        let(:order) { create(:completed_order_with_totals) }
        let(:line_item) { order.line_items.first }

        before do
          expect(line_item.quantity).to eq(1)
          expect(line_item.variant.on_hand).to eq(4)

          expect(order.shipment.inventory_units).to_not be_empty
          expect(order.shipment.inventory_units_for(line_item.variant).size).to eq(1)
        end

        context "when adding all variant.on_hand quantity to existing line_item quantity" do
          it "succeeds because it excludes existing inventory units from the validation" do
            line_item.quantity += line_item.variant.on_hand
            validator.validate(line_item)
            expect(line_item.errors[:quantity].size).to eq(0)
          end

          it "fails if one more item is added" do
            line_item.quantity += line_item.variant.on_hand + 1
            validator.validate(line_item)
            expect_product_out_of_stock_error
          end
        end
      end

      def expect_product_out_of_stock_error
        quantity_error = line_item.errors[:quantity].first
        expect(quantity_error).to include(line_item.variant.product.name)
        expect(quantity_error).to include("out of stock")
      end
    end
  end
end
