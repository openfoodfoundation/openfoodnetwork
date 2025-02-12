# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Orders::HandleFeesService do
  let(:order_cycle) { create(:order_cycle) }
  let(:order) { create(:order_with_line_items, line_items_count: 1, order_cycle:) }
  let(:line_item) { order.line_items.first }

  let(:service) { Orders::HandleFeesService.new(order) }
  let(:calculator) {
    instance_double(OpenFoodNetwork::EnterpriseFeeCalculator, create_order_adjustments_for: true)
  }

  before do
    allow(service).to receive(:calculator) { calculator }
  end

  describe "#create_or_update_line_item_fees!" do
    context "with no existing fee" do
      it "creates per line item fee adjustments for line items in the order cylce" do
        allow(service).to receive(:provided_by_order_cycle?) { true }
        expect(calculator).to receive(:create_line_item_adjustments_for).with(line_item)

        service.create_or_update_line_item_fees!
      end

      it "does create fee if variant not in Order Cyle" do
        allow(service).to receive(:provided_by_order_cycle?) { false }
        expect(calculator).not_to receive(:create_line_item_adjustments_for).with(line_item)

        service.create_or_update_line_item_fees!
      end
    end

    context "with existing line item fee" do
      let(:fee) { order_cycle.exchanges[0].enterprise_fees.first }
      let(:role) { order_cycle.exchanges[0].role }
      let(:fee_applicator) {
        OpenFoodNetwork::EnterpriseFeeApplicator.new(fee, line_item.variant, role)
      }

      it "updates the line item fee" do
        allow(calculator).to receive(
          :order_cycle_per_item_enterprise_fee_applicators_for
        ).and_return([fee_applicator])
        adjustment = fee.create_adjustment('foo', line_item, true)

        expect do
          service.create_or_update_line_item_fees!
        end.to change { adjustment.reload.updated_at }
      end

      context "when enterprise fee is removed from the order cycle" do
        it "updates the line item fee" do
          adjustment = fee.create_adjustment('foo', line_item, true)
          order_cycle.exchanges.first.enterprise_fees.destroy(fee)
          allow(calculator).to receive(
            :order_cycle_per_item_enterprise_fee_applicators_for
          ).and_return([])

          expect do
            service.create_or_update_line_item_fees!
          end.to change { adjustment.reload.updated_at }
        end
      end

      context "with a new enterprise fee added to the order cylce" do
        let(:new_fee) { create(:enterprise_fee, enterprise: fee.enterprise) }
        let(:fee_applicator2) {
          OpenFoodNetwork::EnterpriseFeeApplicator.new(new_fee, line_item.variant, role)
        }
        let!(:adjustment) { fee.create_adjustment('foo', line_item, true) }

        before do
          allow(service).to receive(:provided_by_order_cycle?) { true }
        end

        it "creates a line item fee for the new fee" do
          allow(calculator).to receive(
            :order_cycle_per_item_enterprise_fee_applicators_for
          ).and_return([fee_applicator2])

          expect(fee_applicator2).to receive(:create_line_item_adjustment).with(line_item)

          service.create_or_update_line_item_fees!
        end

        it "updates existing line item fee" do
          allow(calculator).to receive(
            :order_cycle_per_item_enterprise_fee_applicators_for
          ).and_return([fee_applicator, fee_applicator2])

          expect do
            service.create_or_update_line_item_fees!
          end.to change { adjustment.reload.updated_at }
        end

        context "with variant not included in the order cycle" do
          it "doesn't create a new line item fee" do
            allow(service).to receive(:provided_by_order_cycle?) { false }
            allow(calculator).to receive(
              :order_cycle_per_item_enterprise_fee_applicators_for
            ).and_return([fee_applicator2])

            expect(fee_applicator2).not_to receive(:create_line_item_adjustment).with(line_item)

            service.create_or_update_line_item_fees!
          end
        end
      end
    end
  end

  describe "#create_order_fees!" do
    it "creates per-order adjustment for the order cycle" do
      expect(calculator).to receive(:create_order_adjustments_for).with(order)
      service.create_order_fees!
    end

    it "skips per-order fee adjustments for orders that don't have an order cycle" do
      allow(service).to receive(:order_cycle) { nil }
      expect(calculator).not_to receive(:create_order_adjustments_for)

      service.create_order_fees!
    end
  end

  context "checking if a line item can be provided by the order cycle" do
    it "returns true when the variant is provided" do
      allow(order_cycle).to receive(:variants) { [line_item.variant] }

      expect(service.__send__(:provided_by_order_cycle?, line_item)).to be true
    end

    it "returns false otherwise" do
      allow(order_cycle).to receive(:variants) { [] }

      expect(service.__send__(:provided_by_order_cycle?, line_item)).to be false
    end

    it "returns false when there is no order cycle" do
      allow(order).to receive(:order_cycle) { nil }

      expect(service.__send__(:provided_by_order_cycle?, line_item)).to be false
    end
  end
end
