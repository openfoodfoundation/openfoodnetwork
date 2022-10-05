# frozen_string_literal: true

require 'spec_helper'

describe Shop::OrderCyclesList do
  describe ".active_for" do
    let(:customer) { nil }

    context "when the order cycle is open and the distributor belongs to the order cycle" do
      context "and the distributor is ready for checkout" do
        let(:distributor) { create(:distributor_enterprise, with_payment_and_shipping: true) }

        it "returns the order cycle" do
          open_order_cycle = create(:open_order_cycle, distributors: [distributor])

          expect(Shop::OrderCyclesList.active_for(distributor, customer)).to eq [open_order_cycle]
        end
      end

      context "and the distributor is not ready for checkout" do
        let(:distributor) { create(:distributor_enterprise, with_payment_and_shipping: false) }

        it "returns the order cycle" do
          open_order_cycle = create(:open_order_cycle, distributors: [distributor])

          expect(Shop::OrderCyclesList.active_for(distributor, customer)).to eq [open_order_cycle]
        end
      end
    end

    it "doesn't returns closed order cycles or ones belonging to other distributors" do
      distributor = create(:distributor_enterprise)
      closed_order_cycle = create(:closed_order_cycle, distributors: [distributor])
      other_distributor_order_cycle = create(:open_order_cycle)

      expect(Shop::OrderCyclesList.active_for(distributor, customer)).to be_empty
    end
  end

  describe ".ready_for_checkout_for" do
    let(:customer) { nil }

    context "when the order cycle is open and belongs to the distributor" do
      context "and the distributor is ready for checkout" do
        let(:distributor) { create(:distributor_enterprise, with_payment_and_shipping: true) }

        it "returns the order cycle" do
          open_order_cycle = create(:open_order_cycle, distributors: [distributor])

          expect(Shop::OrderCyclesList.ready_for_checkout_for(distributor, customer)).to eq [
            open_order_cycle
          ]
        end
      end

      context "but the distributor not is ready for checkout" do
        let(:distributor) { create(:distributor_enterprise, with_payment_and_shipping: false) }

        it "doesn't return the order cycle" do
          open_order_cycle = create(:open_order_cycle, distributors: [distributor])

          expect(Shop::OrderCyclesList.ready_for_checkout_for(distributor, customer)).to be_empty
        end
      end
    end
  end
end
