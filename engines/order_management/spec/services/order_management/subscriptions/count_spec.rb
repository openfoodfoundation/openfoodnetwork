# frozen_string_literal: true

require 'spec_helper'

module OrderManagement
  module Subscriptions
    describe Count do
      let(:oc1) { create(:simple_order_cycle) }
      let(:oc2) { create(:simple_order_cycle) }
      let(:subscriptions_count) { Count.new(order_cycles) }

      describe "#for" do
        context "when the collection has not been set" do
          let(:order_cycles) { nil }
          it "returns 0" do
            expect(subscriptions_count.for(oc1.id)).to eq 0
          end
        end

        context "when the collection has been set" do
          let(:order_cycles) { OrderCycle.where(id: [oc1]) }
          let!(:po1) { create(:proxy_order, order_cycle: oc1) }
          let!(:po2) { create(:proxy_order, order_cycle: oc1) }
          let!(:po3) { create(:proxy_order, order_cycle: oc2) }

          context "but the requested id is not present in the list of order cycles provided" do
            it "returns 0" do
              # Note that po3 applies to oc2, but oc2 in not in the collection
              expect(subscriptions_count.for(oc2.id)).to eq 0
            end
          end

          context "and the requested id is present in the list of order cycles provided" do
            it "returns a count of active proxy orders associated with the requested order cycle" do
              expect(subscriptions_count.for(oc1.id)).to eq 2
            end
          end
        end
      end
    end
  end
end
