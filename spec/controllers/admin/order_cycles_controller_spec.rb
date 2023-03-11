# frozen_string_literal: true

require 'spec_helper'

module Admin
  describe OrderCyclesController, type: :controller do
    let!(:distributor_owner) { create(:user) }

    before do
      allow(controller).to receive_messages spree_current_user: distributor_owner
    end

    describe "#index" do
      describe "when the user manages a coordinator" do
        let!(:coordinator) { create(:distributor_enterprise, owner: distributor_owner) }
        let!(:oc1) {
          create(:simple_order_cycle, orders_open_at: 70.days.ago, orders_close_at: 60.days.ago )
        }
        let!(:oc2) {
          create(:simple_order_cycle, orders_open_at: 70.days.ago, orders_close_at: 40.days.ago )
        }
        let!(:oc3) {
          create(:simple_order_cycle, orders_open_at: 70.days.ago, orders_close_at: 20.days.ago )
        }
        let!(:oc4) {
          create(:simple_order_cycle, orders_open_at: 70.days.ago, orders_close_at: nil )
        }

        context "html" do
          it "doesn't load any data" do
            get :index, as: :html
            expect(assigns(:collection)).to be_empty
          end
        end

        context "json" do
          context "where ransack conditions are specified" do
            it "loads order cycles that closed within the past month, and orders without a close_at date" do
              get :index, as: :json
              expect(assigns(:collection)).to_not include oc1, oc2
              expect(assigns(:collection)).to include oc3, oc4
            end
          end

          context "where q[orders_close_at_gt] is set" do
            let(:q) { { orders_close_at_gt: 45.days.ago } }

            it "loads order cycles that closed after the specified date, and orders without a close_at date" do
              get :index, as: :json, params: { q: q }
              expect(assigns(:collection)).to_not include oc1
              expect(assigns(:collection)).to include oc2, oc3, oc4
            end

            context "and other conditions are specified" do
              before { q.merge!(id_not_in: [oc2.id, oc4.id]) }

              it "loads order cycles that meet all conditions" do
                get :index, format: :json, params: { q: q }
                expect(assigns(:collection)).to_not include oc1, oc2, oc4
                expect(assigns(:collection)).to include oc3
              end
            end
          end
        end
      end
    end

    describe "new" do
      describe "when the user manages a single distributor enterprise suitable for coordinator" do
        let!(:distributor) { create(:distributor_enterprise, owner: distributor_owner) }

        it "renders the new template" do
          get :new
          expect(response).to render_template :new
        end
      end

      describe "when a user manages multiple enterprises suitable for coordinator" do
        let!(:distributor1) { create(:distributor_enterprise, owner: distributor_owner) }
        let!(:distributor2) { create(:distributor_enterprise, owner: distributor_owner) }
        let!(:distributor3) { create(:distributor_enterprise) }

        it "renders the set_coordinator template" do
          get :new
          expect(response).to render_template :set_coordinator
        end

        describe "and a coordinator_id is submitted as part of the request" do
          describe "when the user manages the enterprise" do
            it "renders the new template" do
              get :new, params: { coordinator_id: distributor1.id }
              expect(response).to render_template :new
            end
          end

          describe "when the user does not manage the enterprise" do
            it "renders the set_coordinator template and sets a flash error" do
              get :new, params: { coordinator_id: distributor3.id }
              expect(response).to render_template :set_coordinator
              expect(flash[:error]).to eq "You don't have permission to create an order cycle coordinated by that enterprise"
            end
          end
        end
      end
    end

    describe "show" do
      context 'a distributor manages an order cycle' do
        let(:distributor) { create(:distributor_enterprise, owner: distributor_owner) }
        let(:oc) { create(:simple_order_cycle, coordinator: distributor) }

        context "distributor navigates to order cycle show page" do
          it 'redirects to edit page' do
            get :show, params: { id: oc.id }
            expect(response).to redirect_to edit_admin_order_cycle_path(oc.id)
          end
        end
      end

      describe "queries" do
        context "as manager, when order cycle has multiple exchanges" do
          let!(:distributor) { create(:distributor_enterprise) }
          let(:order_cycle) { create(:simple_order_cycle, coordinator: distributor) }
          before do
            order_cycle.exchanges.create! sender: distributor, receiver: distributor, incoming: true,
                                          receival_instructions: 'A', tag_list: "A"
            order_cycle.exchanges.create! sender: distributor, receiver: distributor, incoming: false,
                                          pickup_instructions: 'B', tag_list: "B"
            controller_login_as_enterprise_user([distributor])
          end

          it do
            query_counter = QueryCounter.new
            get :show, params: { id: order_cycle.id }, as: :json
            expect(query_counter.queries).to eq(
              {
                select: {
                  enterprise_fees: 3,
                  enterprise_groups: 1,
                  enterprises: 22,
                  exchanges: 7,
                  order_cycles: 6,
                  proxy_orders: 1,
                  schedules: 1,
                  spree_roles: 9,
                  spree_variants: 8,
                  tags: 1
                },
                update: { spree_users: 1 }
              }
            )
            query_counter.stop
          end
        end
      end
    end

    describe "create" do
      let(:shop) { create(:distributor_enterprise) }

      context "as a manager of a shop" do
        let(:form_mock) { instance_double(OrderCycleForm) }
        let(:params) { { as: :json, order_cycle: {} } }

        before do
          controller_login_as_enterprise_user([shop])
          allow(OrderCycleForm).to receive(:new) { form_mock }
        end

        context "when creation is successful" do
          before { allow(form_mock).to receive(:save) { true } }

          # mock build_resource so that we can control the edit_path
          OrderCyclesController.class_eval do
            def build_resource
              order_cycle = OrderCycle.new
              order_cycle.id = 1
              order_cycle
            end
          end

          it "returns success: true and a valid edit path" do
            spree_post :create, params
            json_response = JSON.parse(response.body)
            expect(json_response['success']).to be true
            expect(json_response['edit_path']).to eq "/admin/order_cycles/1/incoming"
          end
        end

        context "when an error occurs" do
          before { allow(form_mock).to receive(:save) { false } }

          it "returns an errors hash" do
            spree_post :create, params
            json_response = JSON.parse(response.body)
            expect(json_response['errors']).to be
          end
        end
      end
    end

    describe "update" do
      let(:order_cycle) { create(:simple_order_cycle) }
      let(:coordinator) { order_cycle.coordinator }
      let(:form_mock) { instance_double(OrderCycleForm) }

      before do
        allow(OrderCycleForm).to receive(:new) { form_mock }
      end

      context "as a manager of the coordinator" do
        before { controller_login_as_enterprise_user([coordinator]) }
        let(:params) { { format: :json, id: order_cycle.id, order_cycle: {} } }

        context "when order cycle has subscriptions" do
          let(:coordinator) { order_cycle.coordinator }
          let(:producer) { create(:supplier_enterprise) }
          let!(:schedule) { create(:schedule, order_cycles: [order_cycle]) }
          let!(:p) { create(:product) }
          let!(:v) { p.variants.first }
          let!(:incoming_exchange) {
            create(:exchange, order_cycle: order_cycle, sender: producer, receiver: coordinator,
                              incoming: true, variants: [v])
          }
          let!(:outgoing_exchange) {
            create(:exchange, order_cycle: order_cycle, sender: coordinator, receiver: coordinator,
                              incoming: false, variants: [v])
          }
          let!(:subscription) { create(:subscription, shop: coordinator, schedule: schedule) }
          let!(:subscription_line_item) { create(:subscription_line_item, subscription: subscription, variant: v) }

          before do
            allow(form_mock).to receive(:save) { true }
            v.destroy
          end

          it "can update order cycle even if the variant has been deleted" do
            spree_put :update, { format: :json, id: order_cycle.id, order_cycle: {} }
            expect(response.status).to eq 200
          end
        end

        context "when updating succeeds" do
          before { allow(form_mock).to receive(:save) { true } }

          context "when the page is reloading" do
            before { params[:reloading] = '1' }

            it "sets flash message" do
              spree_put :update, params
              expect(flash[:notice]).to eq('Your order cycle has been updated.')
            end
          end

          context "when the page is not reloading" do
            it "does not set flash message" do
              spree_put :update, params
              expect(flash[:notice]).to be nil
            end
          end
        end

        context "when a validation error occurs" do
          before { allow(form_mock).to receive(:save) { false } }

          it "returns an error message" do
            spree_put :update, params

            json_response = JSON.parse(response.body)
            expect(json_response['errors']).to be
          end
        end

        it "can update preference product_selection_from_coordinator_inventory_only" do
          expect(OrderCycleForm).to receive(:new).
            with(order_cycle,
                 { "preferred_product_selection_from_coordinator_inventory_only" => true },
                 anything) { form_mock }
          allow(form_mock).to receive(:save) { true }

          spree_put :update, params.
            merge(order_cycle: { preferred_product_selection_from_coordinator_inventory_only: true })
        end

        it "can update preference automatic_notifications" do
          expect(OrderCycleForm).to receive(:new).
            with(order_cycle,
                 { "automatic_notifications" => true },
                 anything) { form_mock }
          allow(form_mock).to receive(:save) { true }

          spree_put :update, params.
            merge(order_cycle: { automatic_notifications: true })
        end
      end
    end

    describe "limiting update scope" do
      let(:order_cycle) { create(:simple_order_cycle) }
      let(:producer) { create(:supplier_enterprise) }
      let(:coordinator) { order_cycle.coordinator }
      let(:hub) { create(:distributor_enterprise) }
      let(:v) { create(:variant) }
      let!(:incoming_exchange) {
        create(:exchange, order_cycle: order_cycle, sender: producer, receiver: coordinator,
                          incoming: true, variants: [v])
      }
      let!(:outgoing_exchange) {
        create(:exchange, order_cycle: order_cycle, sender: coordinator, receiver: hub, incoming: false,
                          variants: [v])
      }

      let(:allowed) { { incoming_exchanges: [], outgoing_exchanges: [] } }
      let(:restricted) {
        { name: 'some name', orders_open_at: 1.day.from_now.to_s, orders_close_at: 1.day.ago.to_s }
      }
      let(:params) { { format: :json, id: order_cycle.id, order_cycle: allowed.merge(restricted) } }
      let(:form_mock) { instance_double(OrderCycleForm, save: true) }

      before { allow(controller).to receive(:spree_current_user) { user } }

      context "as a manager of the coordinator" do
        let(:user) { coordinator.owner }
        let(:expected) { [order_cycle, allowed.merge(restricted), user] }

        it "allows me to update exchange information for exchanges, name and dates" do
          expect(OrderCycleForm).to receive(:new).with(*expected) { form_mock }
          spree_put :update, params
        end
      end

      context "as a producer supplying to an order cycle" do
        let(:user) { producer.owner }
        let(:expected) { [order_cycle, allowed, user] }

        it "allows me to update exchange information for exchanges, but not name or dates" do
          expect(OrderCycleForm).to receive(:new).with(*expected) { form_mock }
          spree_put :update, params
        end
      end
    end

    describe "bulk_update" do
      let(:oc) { create(:simple_order_cycle) }
      let!(:coordinator) { oc.coordinator }

      context "when I manage the coordinator of an order cycle" do
        let(:params) do
          { format: :json, order_cycle_set: { collection_attributes: { '0' => {
            id: oc.id,
            name: "Updated Order Cycle",
            orders_open_at: Date.current - 21.days,
            orders_close_at: Date.current + 21.days,
          } } } }
        end

        before { create(:enterprise_role, user: distributor_owner, enterprise: coordinator) }

        it "updates order cycle properties" do
          spree_put :bulk_update, params
          oc.reload
          expect(oc.name).to eq "Updated Order Cycle"
          expect(oc.orders_open_at.to_date).to eq Date.current - 21.days
          expect(oc.orders_close_at.to_date).to eq Date.current + 21.days
        end

        it "does nothing when no data is supplied" do
          expect do
            spree_put :bulk_update, format: :json
          end.to change(oc, :orders_open_at).by(0)
          json_response = JSON.parse(response.body)
          expect(json_response['errors']).to eq 'Hm, something went wrong. No order cycle data found.'
        end

        context "when a validation error occurs" do
          let(:params) do
            { format: :json, order_cycle_set: { collection_attributes: { '0' => {
              id: oc.id,
              name: "Updated Order Cycle",
              orders_open_at: Date.current + 25.days,
              orders_close_at: Date.current + 21.days,
            } } } }
          end

          it "returns an error message" do
            spree_put :bulk_update, params
            json_response = JSON.parse(response.body)
            expect(json_response['errors']).to be_present
          end
        end
      end

      context "when I do not manage the coordinator of an order cycle" do
        # I need to manage a hub in order to access the bulk_update action
        let!(:another_distributor) { create(:distributor_enterprise, users: [distributor_owner]) }

        it "doesn't update order cycle properties" do
          spree_put :bulk_update, format: :json, order_cycle_set: { collection_attributes: { '0' => {
            id: oc.id,
            name: "Updated Order Cycle",
            orders_open_at: Date.current - 21.days,
            orders_close_at: Date.current + 21.days,
          } } }

          oc.reload
          expect(oc.name).to_not eq "Updated Order Cycle"
          expect(oc.orders_open_at.to_date).to_not eq Date.current - 21.days
          expect(oc.orders_close_at.to_date).to_not eq Date.current + 21.days
        end
      end
    end

    describe "notifying producers" do
      let(:user) { create(:user) }
      let(:admin_user) do
        user = create(:user)
        user.spree_roles << Spree::Role.find_or_create_by!(name: 'admin')
        user
      end
      let(:order_cycle) { create(:simple_order_cycle) }

      before do
        allow(controller).to receive_messages spree_current_user: admin_user
      end

      it "enqueues a job" do
        expect do
          spree_post :notify_producers, id: order_cycle.id
        end.to enqueue_job OrderCycleNotificationJob
      end

      it "redirects back to the order cycles path with a success message" do
        spree_post :notify_producers, id: order_cycle.id
        expect(response).to redirect_to admin_order_cycles_path
        expect(flash[:notice]).to eq('Emails to be sent to producers have been queued for sending.')
      end
    end

    describe "destroy" do
      let(:distributor) { create(:distributor_enterprise, owner: distributor_owner) }
      let(:oc) { create(:simple_order_cycle, coordinator: distributor) }

      describe "when an order cycle is deleteable" do
        it "allows the order_cycle to be destroyed" do
          get :destroy, params: { id: oc.id }
          expect(OrderCycle.find_by(id: oc.id)).to be nil
        end
      end

      describe "when an order cycle becomes non-deletable due to the presence of an order" do
        let!(:order) { create(:order, order_cycle: oc) }

        it "displays an error message when we attempt to delete it" do
          get :destroy, params: { id: oc.id }
          expect(response).to redirect_to admin_order_cycles_path
          expect(flash[:error]).to eq 'That order cycle has been selected by a customer and cannot be deleted. To prevent customers from accessing it, please close it instead.'
        end
      end

      describe "when an order cycle becomes non-deletable because it is linked to a schedule" do
        let!(:schedule) { create(:schedule, order_cycles: [oc]) }

        it "displays an error message when we attempt to delete it" do
          get :destroy, params: { id: oc.id }
          expect(response).to redirect_to admin_order_cycles_path
          expect(flash[:error]).to eq 'That order cycle is linked to a schedule and cannot be deleted. Please unlink or delete the schedule first.'
        end
      end

      describe "when an order cycle has any coordinator_fees" do
        let(:enterprise_fee1) { create(:enterprise_fee) }

        before do
          oc.coordinator_fees << enterprise_fee1
        end

        it "actually delete the order cycle" do
          get :destroy, params: { id: oc.id }
          expect(OrderCycle.find_by(id: oc.id)).to be nil
          expect(response).to redirect_to admin_order_cycles_path
        end

        describe "when the order_cycle was previously cloned" do
          let(:cloned) { oc.clone! }

          it "actually delete the order cycle" do
            get :destroy, params: { id: cloned.id }

            expect(OrderCycle.find_by(id: cloned.id)).to be nil
            expect(OrderCycle.find_by(id: oc.id)).to_not be nil
            expect(EnterpriseFee.find_by(id: enterprise_fee1.id)).to_not be nil
            expect(response).to redirect_to admin_order_cycles_path
          end
        end
      end
    end
  end
end
