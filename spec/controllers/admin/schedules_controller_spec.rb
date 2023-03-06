# frozen_string_literal: true

require 'spec_helper'

describe Admin::SchedulesController, type: :controller do
  include AuthenticationHelper

  describe "index" do
    let!(:coordinated_order_cycle) { create(:simple_order_cycle) }
    let!(:managed_coordinator) { coordinated_order_cycle.coordinator }
    let!(:other_order_cycle) { create(:simple_order_cycle, coordinator: create(:enterprise)) }
    let!(:coordinated_schedule) { create(:schedule, order_cycles: [coordinated_order_cycle] ) }
    let!(:uncoordinated_schedule) { create(:schedule, order_cycles: [other_order_cycle] ) }

    context "json" do
      context "where I manage an order cycle coordinator" do
        before do
          allow(controller).to receive_messages spree_current_user: managed_coordinator.owner
        end

        let(:params) { { format: :json } }

        it "scopes @collection to schedules containing order_cycles coordinated by enterprises I manage" do
          get :index, params: params
          expect(assigns(:collection)).to eq [coordinated_schedule]
        end

        it "serializes the data" do
          expect(ActiveModel::ArraySerializer).to receive(:new)
          get :index, params: params
        end

        context "and there is a schedule of an OC coordinated by _another_ enterprise I manage and the first enterprise is given" do
          let!(:other_managed_coordinator) {
            create(:distributor_enterprise, owner: managed_coordinator.owner)
          }
          let!(:other_coordinated_order_cycle) {
            create(:simple_order_cycle, coordinator: other_managed_coordinator)
          }
          let!(:other_coordinated_schedule) {
            create(:schedule, order_cycles: [other_coordinated_order_cycle] )
          }
          let(:params) { { format: :json, enterprise_id: managed_coordinator.id } }

          it "scopes @collection to schedules containing order_cycles coordinated by the first enterprise" do
            get :index, params: params
            expect(assigns(:collection)).to eq [coordinated_schedule]
          end
        end
      end

      context "where I dont manage an order cycle coordinator" do
        it "returns an empty collection" do
          get :index, as: :json
          expect(assigns(:collection)).to be_nil
        end
      end
    end
  end

  describe "update" do
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
    let!(:uncoordinated_order_cycle2) {
      create(:simple_order_cycle, coordinator: create(:enterprise))
    }
    let!(:uncoordinated_order_cycle3) {
      create(:simple_order_cycle, coordinator: create(:enterprise))
    }
    let!(:coordinated_schedule) {
      create(:schedule,
             order_cycles: [coordinated_order_cycle, uncoordinated_order_cycle,
                            uncoordinated_order_cycle3] )
    }
    let!(:uncoordinated_schedule) { create(:schedule, order_cycles: [uncoordinated_order_cycle] ) }

    context "json" do
      context "where I manage at least one of the schedule's coordinators" do
        render_views

        before do
          allow(controller).to receive_messages spree_current_user: user
        end

        it "allows me to update basic information" do
          spree_put :update, format: :json, id: coordinated_schedule.id,
                             schedule: { name: "my awesome schedule" }
          expect(JSON.parse(response.body)["id"]).to eq coordinated_schedule.id
          expect(JSON.parse(response.body)["name"]).to eq "my awesome schedule"
          expect(assigns(:schedule)).to eq coordinated_schedule
          expect(coordinated_schedule.reload.name).to eq 'my awesome schedule'
        end

        it "allows me to add/remove only order cycles I coordinate to/from the schedule" do
          order_cycle_ids = [coordinated_order_cycle2.id, uncoordinated_order_cycle2.id,
                             uncoordinated_order_cycle3.id]
          spree_put :update, format: :json, id: coordinated_schedule.id,
                             order_cycle_ids: order_cycle_ids
          expect(assigns(:schedule)).to eq coordinated_schedule
          # coordinated_order_cycle2 is added, uncoordinated_order_cycle is NOT removed
          expect(coordinated_schedule.reload.order_cycles).to include coordinated_order_cycle2,
                                                                      uncoordinated_order_cycle, uncoordinated_order_cycle3
          # coordinated_order_cycle is removed, uncoordinated_order_cycle2 is NOT added
          expect(coordinated_schedule.reload.order_cycles).to_not include coordinated_order_cycle,
                                                                          uncoordinated_order_cycle2
        end

        it "syncs proxy orders when order_cycle_ids change" do
          syncer_mock = double(:syncer)
          allow(OrderManagement::Subscriptions::ProxyOrderSyncer).to receive(:new) { syncer_mock }
          expect(syncer_mock).to receive(:sync!).exactly(2).times

          spree_put :update, format: :json, id: coordinated_schedule.id,
                             order_cycle_ids: [coordinated_order_cycle.id, coordinated_order_cycle2.id]
          spree_put :update, format: :json, id: coordinated_schedule.id,
                             order_cycle_ids: [coordinated_order_cycle.id]
          spree_put :update, format: :json, id: coordinated_schedule.id,
                             order_cycle_ids: [coordinated_order_cycle.id]
        end
      end

      context "where I don't manage any of the schedule's coordinators" do
        before do
          allow(controller).to receive_messages spree_current_user: uncoordinated_order_cycle2.coordinator.owner
        end

        it "prevents me from updating the schedule" do
          spree_put :update, format: :json, id: coordinated_schedule.id,
                             schedule: { name: "my awesome schedule" }
          expect(response).to redirect_to unauthorized_path
          expect(assigns(:schedule)).to eq nil
          expect(coordinated_schedule.name).to_not eq "my awesome schedule"
        end
      end
    end
  end

  describe "create" do
    let(:user) { create(:user) }
    let!(:managed_coordinator) { create(:enterprise, owner: user) }
    let!(:coordinated_order_cycle) {
      create(:simple_order_cycle, coordinator: managed_coordinator )
    }
    let!(:uncoordinated_order_cycle) {
      create(:simple_order_cycle, coordinator: create(:enterprise))
    }

    def create_schedule(params)
      spree_put :create, params
    end

    context "json" do
      let(:params) { { format: :json, schedule: { name: 'new schedule' } } }

      context 'as an enterprise user' do
        before { allow(controller).to receive(:spree_current_user) { user } }

        context "where no order cycles ids are provided" do
          it "does not allow me to create the schedule" do
            expect { create_schedule params }.to_not change(Schedule, :count)
          end
        end

        context "where I manage at least one of the order cycles to be added to the schedules" do
          before do
            params.merge!( order_cycle_ids: [coordinated_order_cycle.id,
                                             uncoordinated_order_cycle.id] )
          end

          it "allows me to create the schedule, adding only order cycles that I manage" do
            expect { create_schedule params }.to change(Schedule, :count).by(1)
            schedule = Schedule.last
            expect(schedule.order_cycles).to include coordinated_order_cycle
            expect(schedule.order_cycles).to_not include uncoordinated_order_cycle
          end

          it "sync proxy orders" do
            syncer_mock = double(:syncer)
            allow(OrderManagement::Subscriptions::ProxyOrderSyncer).to receive(:new) { syncer_mock }
            expect(syncer_mock).to receive(:sync!).once

            create_schedule params
          end
        end

        context "where I don't manage any of the order cycles to be added to the schedules" do
          before do
            params.merge!( order_cycle_ids: [uncoordinated_order_cycle.id] )
          end

          it "prevents me from creating the schedule" do
            expect { create_schedule params }.to_not change(Schedule, :count)
          end
        end
      end

      context 'as an admin user' do
        before do
          allow(controller).to receive(:spree_current_user) { create(:admin_user) }
          params.merge!( order_cycle_ids: [coordinated_order_cycle.id,
                                           uncoordinated_order_cycle.id] )
        end

        it "allows me to create a schedule" do
          expect { create_schedule params }.to change(Schedule, :count).by(1)
          schedule = Schedule.last
          expect(schedule.order_cycles).to include coordinated_order_cycle,
                                                   uncoordinated_order_cycle
        end
      end
    end
  end

  describe "destroy" do
    let(:user) { create(:user, enterprise_limit: 10) }
    let(:managed_coordinator) { create(:enterprise, owner: user) }
    let(:coordinated_order_cycle) { create(:simple_order_cycle, coordinator: managed_coordinator ) }
    let(:uncoordinated_order_cycle) {
      create(:simple_order_cycle, coordinator: create(:enterprise) )
    }
    let(:coordinated_schedule) {
      create(:schedule, order_cycles: [coordinated_order_cycle, uncoordinated_order_cycle] )
    }
    let(:uncoordinated_schedule) { create(:schedule, order_cycles: [uncoordinated_order_cycle] ) }
    let(:params) { { format: :json } }

    context "json" do
      context 'as an enterprise user' do
        before { allow(controller).to receive(:spree_current_user) { user } }

        context "where I manage at least one of the schedule's coordinators" do
          before { params.merge!(id: coordinated_schedule.id) }

          context "when no dependent subscriptions are present" do
            it "allows me to destroy the schedule" do
              expect { spree_delete :destroy, params }.to change(Schedule, :count).by(-1)
            end
          end

          context "when a dependent subscription is present" do
            let!(:subscription) { create(:subscription, schedule: coordinated_schedule) }

            it "returns an error message and prevents me from deleting the schedule" do
              expect { spree_delete :destroy, params }.to_not change(Schedule, :count)
              json_response = JSON.parse(response.body)
              expect(json_response["errors"]).to include 'This schedule cannot be deleted because it has associated subscriptions'
            end
          end
        end

        context "where I don't manage any of the schedule's coordinators" do
          before { params.merge!(id: uncoordinated_schedule.id) }

          it "prevents me from destroying the schedule" do
            expect { spree_delete :destroy, params }.to_not change(Schedule, :count)
          end
        end
      end
    end
  end
end
