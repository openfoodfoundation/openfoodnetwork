# frozen_string_literal: true

RSpec.describe Orders::HandleFeesService do
  let(:order_cycle) { create(:order_cycle) }
  let(:order) {
    create(:order_with_line_items, line_items_count: 1, order_cycle:,
                                   distributor: order_cycle.distributors.first)
  }
  let(:line_item) { order.line_items.first }

  let(:service) { Orders::HandleFeesService.new(order) }
  let(:calculator) {
    instance_double(OpenFoodNetwork::EnterpriseFeeCalculator, create_order_adjustments_for: true)
  }

  before do
    allow(service).to receive(:calculator) { calculator }
  end

  describe "#recreate_all_fees!" do
    before do
      allow(order).to receive(:update_order!)
    end

    it "clears order enterprise fee adjustments on the order" do
      expect(EnterpriseFee).to receive(:clear_order_adjustments).with(order)

      service.recreate_all_fees!
    end

    # both create_or_update_line_item_fees! and create_order_fees! are tested below,
    # so it's enough to check they get called
    it "creates line item and order fee adjustments" do
      expect(service).to receive(:create_or_update_line_item_fees!)
      expect(service).to receive(:create_order_fees!)

      service.recreate_all_fees!
    end

    it "updates the order" do
      expect(order).to receive(:update_order!)

      service.recreate_all_fees!
    end

    it "doesn't create tax adjustment" do
      expect(service).not_to receive(:tax_enterprise_fees!)

      service.recreate_all_fees!
    end

    context "when after payment state" do
      it "creates the tax adjustment for the fees" do
        expect(service).to receive(:tax_enterprise_fees!)

        order.update(state: "confirmation")
        service.recreate_all_fees!
      end
    end
  end

  describe "#create_or_update_line_item_fees!" do
    context "with no existing fee" do
      it "creates per line item fee adjustments for line items in the order cycle" do
        allow(service).to receive(:provided_by_order_cycle?) { true }
        expect(calculator).to receive(:create_line_item_adjustments_for).with(line_item)

        service.create_or_update_line_item_fees!
      end

      it "does not create fee if variant not in Order Cycle" do
        allow(service).to receive(:provided_by_order_cycle?) { false }
        expect(calculator).not_to receive(:create_line_item_adjustments_for).with(line_item)

        service.create_or_update_line_item_fees!
      end
    end

    context "with existing line item fee" do
      let(:fee) { order_cycle.exchanges.first.enterprise_fees.first }
      let(:role) { order_cycle.exchanges.first.role }
      let(:fee_applicator) {
        OpenFoodNetwork::EnterpriseFeeApplicator.new(fee, line_item.variant, role)
      }

      it "updates the line item fee" do
        allow(calculator).to receive(
          :per_item_enterprise_fee_applicators_for
        ).and_return([fee_applicator])
        adjustment = fee_applicator.create_line_item_adjustment(line_item)

        expect do
          service.create_or_update_line_item_fees!
        end.to change { adjustment.reload.updated_at }
      end

      context "when the variant has been removed from the order cycle" do
        it "updates the line item fee" do
          allow(calculator).to receive(
            :per_item_enterprise_fee_applicators_for
          ).and_return([])
          adjustment = fee_applicator.create_line_item_adjustment(line_item)

          expect do
            service.create_or_update_line_item_fees!
          end.to change { adjustment.reload.updated_at }
        end
      end

      context "when enterprise fee is removed from the order cycle" do
        it "removes the line item fee" do
          adjustment = fee_applicator.create_line_item_adjustment(line_item)
          order_cycle.exchanges.first.enterprise_fees.destroy(fee)
          allow(calculator).to receive(
            :per_item_enterprise_fee_applicators_for
          ).and_return([])

          expect do
            service.create_or_update_line_item_fees!
          end.to change { line_item.adjustments.reload.enterprise_fee.count }.by(-1)
        end

        context "with coordinator fee" do
          it "removes the coordinator fee" do
            coordinator_fee = order_cycle.coordinator_fees.per_item.first
            adjustment = coordinator_fee.create_adjustment('foo', line_item, true)
            order_cycle.coordinator_fees.destroy(coordinator_fee)
            allow(calculator).to receive(
              :per_item_enterprise_fee_applicators_for
            ).and_return([])

            expect do
              service.create_or_update_line_item_fees!
            end.to change { line_item.adjustments.reload.enterprise_fee.count }.by(-1)
          end
        end

        context "with the same fee used for both supplier an distributor" do
          let!(:supplier_adjustment) {
            fee_applicator.create_line_item_adjustment(line_item)
          }
          let!(:distributor_adjustment) {
            distributor_applicator.create_line_item_adjustment(line_item)
          }
          let(:distributor_applicator) {
            OpenFoodNetwork::EnterpriseFeeApplicator.new(fee, line_item.variant,
                                                         distributor_exchange.role)
          }
          let(:supplier_exchange) { order_cycle.cached_incoming_exchanges.first }
          let(:distributor_exchange) { order_cycle.cached_outgoing_exchanges.first }

          before do
            # Use the supplier fee for the distributor
            distributor_exchange.enterprise_fees = [fee]
          end

          it "removes the supplier fee when removed from the order cycle" do
            # Delete supplier fee
            supplier_exchange.enterprise_fees.destroy(fee)
            allow(calculator).to receive(
              :per_item_enterprise_fee_applicators_for
            ).and_return([distributor_applicator])

            enterprise_fees = line_item.adjustments.reload.enterprise_fee
            expect do
              service.create_or_update_line_item_fees!
            end.to change { enterprise_fees.count }.by(-1)
            expect(enterprise_fees).not_to include(supplier_adjustment)
          end

          it "removes the distributor fee when removed from the order cycle" do
            # Delete distributor fee
            distributor_exchange.enterprise_fees.destroy(fee)
            allow(calculator).to receive(
              :per_item_enterprise_fee_applicators_for
            ).and_return([fee_applicator])

            enterprise_fees = line_item.adjustments.reload.enterprise_fee
            expect do
              service.create_or_update_line_item_fees!
            end.to change { enterprise_fees.count }.by(-1)
            expect(enterprise_fees).not_to include(distributor_adjustment)
          end
        end
      end

      context "when an enterprise fee is deleted" do
        before do
          fee.create_adjustment('foo', line_item, true)
          allow(calculator).to receive(
            :per_item_enterprise_fee_applicators_for
          ).and_return([])
        end

        context "soft delete" do
          it "deletes the line item fee" do
            fee.destroy

            expect do
              service.create_or_update_line_item_fees!
            end.to change { line_item.adjustments.enterprise_fee.count }.by(-1)
          end
        end

        context "hard delete" do
          it "deletes the line item fee" do
            fee.really_destroy!

            expect do
              service.create_or_update_line_item_fees!
            end.to change { line_item.adjustments.enterprise_fee.count }.by(-1)
          end
        end
      end

      context "with a new enterprise fee added to the order cycle" do
        let(:new_fee) { create(:enterprise_fee, enterprise: fee.enterprise) }
        let(:fee_applicator2) {
          OpenFoodNetwork::EnterpriseFeeApplicator.new(new_fee, line_item.variant, role)
        }
        let!(:adjustment) { fee_applicator.create_line_item_adjustment(line_item) }

        before do
          allow(service).to receive(:provided_by_order_cycle?) { true }
          # add the new fee to the order cycle
          order_cycle.cached_outgoing_exchanges.first.enterprise_fees << new_fee
        end

        it "creates a line item fee for the new fee" do
          allow(calculator).to receive(
            :per_item_enterprise_fee_applicators_for
          ).and_return([fee_applicator, fee_applicator2])

          expect(fee_applicator2).to receive(:create_line_item_adjustment).with(line_item)

          service.create_or_update_line_item_fees!
        end

        it "updates existing line item fee" do
          allow(calculator).to receive(
            :per_item_enterprise_fee_applicators_for
          ).and_return([fee_applicator, fee_applicator2])

          expect do
            service.create_or_update_line_item_fees!
          end.to change { adjustment.reload.updated_at }
        end

        context "with variant not included in the order cycle" do
          it "doesn't create a new line item fee" do
            allow(service).to receive(:provided_by_order_cycle?) { false }
            allow(calculator).to receive(
              :per_item_enterprise_fee_applicators_for
            ).and_return([])

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
