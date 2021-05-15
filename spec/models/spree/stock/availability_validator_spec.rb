# frozen_string_literal: true

require 'spec_helper'

module Spree
  module Stock
    describe AvailabilityValidator do
      let(:validator) { AvailabilityValidator.new({}) }

      context "line item without existing inventory units" do
        let(:order) { create(:order_with_line_items) }
        let(:line_item) { order.line_items.first }

        context "available quantity when variant.on_hand > line_item.quantity" do
          it "suceeds" do
            line_item.quantity = line_item.variant.on_hand - 1
            validator.validate(line_item)
            expect(line_item).to be_valid
          end
        end

        context "unavailable quantity when variant.on_hand < line_item.quantity" do
          it "fails" do
            line_item.quantity = line_item.variant.on_hand + 1
            validator.validate(line_item)
            expect(line_item).not_to be_valid
          end

          it "succeeds with line_item skip_stock_check" do
            line_item.skip_stock_check = true
            line_item.quantity = line_item.variant.on_hand + 1
            validator.validate(line_item)
            expect(line_item).to be_valid
          end
        end
      end

      describe "line item with existing inventory units" do
        let(:order) { create(:completed_order_with_totals) }
        let(:line_item) { order.line_items.first }

        context "when adding all variant.on_hand quantity to existing line_item quantity" do
          it "succeeds because it excludes existing inventory units from the validation" do
            line_item.quantity += line_item.variant.on_hand
            validator.validate(line_item)
            expect(line_item).to be_valid
          end

          it "fails if one more item is added" do
            line_item.quantity += line_item.variant.on_hand + 1
            validator.validate(line_item)
            expect(line_item).not_to be_valid
          end
        end

        context "when the line item's variant has an override" do
          let(:hub) { order.distributor }
          let(:variant) { line_item.variant }
          let(:vo_stock) { 999 }
          let!(:variant_override) {
            create(:variant_override, variant: variant, hub: hub, count_on_hand: vo_stock)
          }

          context "when the override has stock" do
            it "is valid" do
              line_item.quantity = 999
              validator.validate(line_item)
              expect(line_item).to be_valid
            end
          end

          context "when the override is out of stock" do
            let(:vo_stock) { 1 }

            it "is not valid" do
              line_item.quantity = 999
              validator.validate(line_item)
              expect(line_item).to_not be_valid
            end
          end
        end
      end
    end
  end
end
