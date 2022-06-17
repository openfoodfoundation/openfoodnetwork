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

  context "distributor order cycle" do
    let(:order_cycle) { create(:distributor_order_cycle) }
    let(:distributor) { order_cycle.coordinator }
    let(:supplier) { create(:supplier_enterprise) }
    let(:user) { distributor.owner }
    let(:shipping_method) { create(:shipping_method, distributors: [distributor]) }
    let(:variant) { create(:variant, product: create(:product, supplier: supplier)) }
    let(:params) { { name: 'Some new name' } }
    let(:form) { OrderCycleForm.new(order_cycle, params, user) }
    let(:outgoing_exchange_params) do
      {
        enterprise_id: distributor.id,
        incoming: false,
        active: true,
        variants: { variant.id => true },
        pickup_time: "Saturday morning",
        enterprise_fee_ids: []
      }
    end

    context "basic update i.e. without exchanges or shipping methods" do
      it do
        expect(form.save).to be true
        expect(order_cycle.name).to eq 'Some new name'
      end
    end

    context "updating basics, incoming exchanges, outcoming exchanges
             and preferred shipping methods simultaneously" do
      before do
        params.merge!(
          incoming_exchanges: [{
            enterprise_id: supplier.id,
            incoming: true,
            active: true,
            variants: { variant.id => true },
            receival_instructions: "Friday evening",
            enterprise_fee_ids: []
          }],
          outgoing_exchanges: [outgoing_exchange_params],
          preferred_shipping_method_ids: [shipping_method.id]
        )
      end

      it "saves everything i.e. the basics, incoming and outgoing exchanges and shipping methods" do
        expect(form.save).to be true
        expect(order_cycle.name).to eq 'Some new name'
        expect(order_cycle.cached_incoming_exchanges.count).to eq 1
        expect(order_cycle.cached_outgoing_exchanges.count).to eq 1
        expect(order_cycle.shipping_methods).to eq [shipping_method]
      end
    end

    context "updating outgoing exchanges without specifying any shipping methods" do
      before do
        params.merge!(
          outgoing_exchanges: [outgoing_exchange_params],
          preferred_shipping_method_ids: nil
        )
      end

      it "saves the outgoing exchanges,
         it doesn't return a validation error because no shipping methods are present yet" do
        expect(form.save).to be true
        expect(order_cycle.cached_outgoing_exchanges.count).to eq 1
      end
    end

    context "updating outgoing exchanges but specifying an invalid shipping method" do
      let(:other_distributor_shipping_method) do
        create(:shipping_method, distributors: [create(:distributor_enterprise)])
      end

      before do
        params.merge!(
          outgoing_exchanges: [outgoing_exchange_params],
          preferred_shipping_method_ids: [other_distributor_shipping_method.id]
        )
      end

      it "returns a validation error" do
        expect(form.save).to be false
        expect(order_cycle.errors.to_a).to eq [
          "Shipping method must be from a distributor on the order cycle"
        ]
      end
    end

    context "when shipping methods already exist
             and doing an update without the :shipping_methods_id parameter" do
      it "doesn't return a validation error on shipping methods" do
        distributor = create(:distributor_enterprise)
        shipping_method = create(:shipping_method, distributors: [distributor])
        order_cycle = create(:distributor_order_cycle, distributors: [distributor])

        form = OrderCycleForm.new(
          order_cycle,
          params.except(:preferred_shipping_method_ids),
          order_cycle.coordinator
        )

        expect(form.save).to be true
      end
    end

    context "updating shipping methods" do
      context "and it's valid" do
        it "saves the changes" do
          distributor = create(:distributor_enterprise)
          shipping_method = create(:shipping_method, distributors: [distributor])
          order_cycle = create(:distributor_order_cycle, distributors: [distributor])

          form = OrderCycleForm.new(order_cycle,
                                    { preferred_shipping_method_ids: [shipping_method.id] },
                                    order_cycle.coordinator)

          expect(form.save).to be true
          expect(order_cycle.shipping_methods).to eq [shipping_method]
        end
      end

      context "and it's invalid" do
        it "returns a validation error" do
          distributor_i = create(:distributor_enterprise)
          distributor_ii = create(:distributor_enterprise)
          shipping_method_i = create(:shipping_method, distributors: [distributor_i])
          shipping_method_ii = create(:shipping_method, distributors: [distributor_ii])
          order_cycle = create(:distributor_order_cycle,
                               distributors: [distributor_i, distributor_ii])

          form = OrderCycleForm.new(order_cycle,
                                    { preferred_shipping_method_ids: [shipping_method_i.id] },
                                    order_cycle.coordinator)

          expect(form.save).to be false
          expect(order_cycle.errors.to_a).to eq [
            "You need to select at least one shipping method for each distributor"
          ]
        end
      end
    end
  end
end
