# frozen_string_literal: true

require 'spec_helper'
require 'order_management/subscriptions/proxy_order_syncer'

describe OrderCycleForm do
  describe "save" do
    describe "creating a new order cycle from params" do
      let(:shop) { create(:enterprise) }
      let(:order_cycle) { OrderCycle.new }
      let(:form) { OrderCycleForm.new(order_cycle, params, shop.owner) }

      context "when creation is successful" do
        let(:params) { { name: "Test Order Cycle", coordinator_id: shop.id } }

        it "returns true" do
          expect do
            expect(form.save).to be true
          end.to change(OrderCycle, :count).by(1)
        end
      end

      context "when creation fails" do
        let(:params) { { name: "Test Order Cycle" } }

        it "returns false" do
          expect do
            expect(form.save).to be false
          end.to_not change(OrderCycle, :count)
        end
      end
    end

    describe "updating an existing order cycle from params" do
      let(:shop) { create(:enterprise) }
      let(:order_cycle) { create(:simple_order_cycle, name: "Old Name") }
      let(:form) { OrderCycleForm.new(order_cycle, params, shop.owner) }

      context "when update is successful" do
        let(:params) { { name: "Test Order Cycle", coordinator_id: shop.id } }

        it "returns true" do
          expect do
            expect(form.save).to be true
          end.to change(order_cycle.reload, :name).to("Test Order Cycle")
        end
      end

      context "when updating fails" do
        let(:params) { { name: nil } }

        it "returns false" do
          expect do
            expect(form.save).to be false
          end.to_not change{ order_cycle.reload.name }
        end
      end
    end
  end

  describe "updating schedules" do
    let(:user) { create(:user, enterprise_limit: 10) }
    let!(:managed_coordinator) { create(:enterprise, owner: user) }
    let!(:managed_enterprise) { create(:enterprise, owner: user) }
    let!(:coordinated_order_cycle) {
      create(:simple_order_cycle, coordinator: managed_coordinator )
    }
    let!(:coordinated_order_cycle2) {
      create(:simple_order_cycle, coordinator: managed_enterprise )
    }
    let!(:uncoordinated_order_cycle) {
      create(:simple_order_cycle, coordinator: create(:enterprise) )
    }
    let!(:coordinated_schedule) { create(:schedule, order_cycles: [coordinated_order_cycle] ) }
    let!(:coordinated_schedule2) { create(:schedule, order_cycles: [coordinated_order_cycle2] ) }
    let!(:uncoordinated_schedule) { create(:schedule, order_cycles: [uncoordinated_order_cycle] ) }

    context "where I manage the order_cycle's coordinator" do
      let(:form) { OrderCycleForm.new(coordinated_order_cycle, params, user) }
      let(:syncer_mock) {
        instance_double(OrderManagement::Subscriptions::ProxyOrderSyncer, sync!: true)
      }

      before do
        allow(OrderManagement::Subscriptions::ProxyOrderSyncer).to receive(:new) { syncer_mock }
      end

      context "and I add an schedule that I own, and remove another that I own" do
        let(:params) { { schedule_ids: [coordinated_schedule2.id] } }

        it "associates the order cycle to the schedule" do
          expect(form.save).to be true
          expect(coordinated_order_cycle.reload.schedules).to include coordinated_schedule2
          expect(coordinated_order_cycle.reload.schedules).to_not include coordinated_schedule
          expect(syncer_mock).to have_received(:sync!)
        end
      end

      context "and I add a schedule that I don't own" do
        let(:params) { { schedule_ids: [coordinated_schedule.id, uncoordinated_schedule.id] } }

        it "ignores the schedule that I don't own" do
          expect(form.save).to be true
          expect(coordinated_order_cycle.reload.schedules).to include coordinated_schedule
          expect(coordinated_order_cycle.reload.schedules).to_not include uncoordinated_schedule
          expect(syncer_mock).to_not have_received(:sync!)
        end
      end

      context "when I make no changes to the schedule ids" do
        let(:params) { { schedule_ids: [coordinated_schedule.id] } }

        it "ignores the schedule that I don't own" do
          expect(form.save).to be true
          expect(coordinated_order_cycle.reload.schedules).to include coordinated_schedule
          expect(syncer_mock).to_not have_received(:sync!)
        end
      end
    end
  end

  describe "updating exchanges" do
    let(:user) { instance_double(Spree::User) }
    let(:order_cycle) { create(:simple_order_cycle) }
    let(:form_applicator_mock) { instance_double(OpenFoodNetwork::OrderCycleFormApplicator) }
    let(:form) { OrderCycleForm.new(order_cycle, params, user) }
    let(:params) { { name: 'Some new name' } }

    before do
      allow(OpenFoodNetwork::OrderCycleFormApplicator).to receive(:new) { form_applicator_mock }
      allow(form_applicator_mock).to receive(:go!)
    end

    context "when exchange params are provided" do
      let(:exchange_params) { { incoming_exchanges: [], outgoing_exchanges: [] } }
      before { params.merge!(exchange_params) }

      it "runs the OrderCycleFormApplicator, and saves other changes" do
        expect(form.save).to be true
        expect(form_applicator_mock).to have_received(:go!)
        expect(order_cycle.name).to eq 'Some new name'
      end
    end

    context "when no exchange params are provided" do
      it "does not run the OrderCycleFormApplicator, but saves other changes" do
        expect(form.save).to be true
        expect(form_applicator_mock).to_not have_received(:go!)
        expect(order_cycle.name).to eq 'Some new name'
      end
    end
  end
end
