require 'spec_helper'

module Admin
  describe OrderCyclesController, type: :controller do
    include AuthenticationWorkflow

    let!(:distributor_owner) { create_enterprise_user enterprise_limit: 2 }

    before do
      controller.stub spree_current_user: distributor_owner
    end

    describe "#index" do
      describe "when the user manages a coordinator" do
        let!(:coordinator) { create(:distributor_enterprise, owner: distributor_owner) }
        let!(:oc1) { create(:simple_order_cycle, orders_close_at: 60.days.ago ) }
        let!(:oc2) { create(:simple_order_cycle, orders_close_at: 40.days.ago ) }
        let!(:oc3) { create(:simple_order_cycle, orders_close_at: 20.days.ago ) }
        let!(:oc4) { create(:simple_order_cycle, orders_close_at: nil ) }

        context "html" do
          it "doesn't load any data" do
            spree_get :index, format: :html
            expect(assigns(:collection)).to be_empty
          end
        end

        context "json" do
          context "where ransack conditions are specified" do
            it "loads order cycles that closed within the past month, and orders without a close_at date" do
              spree_get :index, format: :json
              expect(assigns(:collection)).to_not include oc1, oc2
              expect(assigns(:collection)).to include oc3, oc4
            end
          end

          context "where q[orders_close_at_gt] is set" do
            let(:q) { { orders_close_at_gt: 45.days.ago } }

            it "loads order cycles that closed after the specified date, and orders without a close_at date" do
              spree_get :index, format: :json, q: q
              expect(assigns(:collection)).to_not include oc1
              expect(assigns(:collection)).to include oc2, oc3, oc4
            end

            context "and other conditions are specified" do
              before { q.merge!(id_not_in: [oc2.id, oc4.id]) }

              it "loads order cycles that meet all conditions" do
                spree_get :index, format: :json, q: q
                expect(assigns(:collection)).to_not include oc1, oc2, oc4
                expect(assigns(:collection)).to include oc3
              end
            end
          end
        end
      end
    end

    describe "new" do
      describe "when the user manages no distributor enterprises suitable for coordinator" do
        let!(:distributor) { create(:distributor_enterprise, owner: distributor_owner, confirmed_at: nil) }

        it "redirects to order cycles index" do
          spree_get :new
          expect(response).to redirect_to admin_order_cycles_path
        end
      end

      describe "when the user manages a single distributor enterprise suitable for coordinator" do
        let!(:distributor) { create(:distributor_enterprise, owner: distributor_owner) }

        it "renders the new template" do
          spree_get :new
          expect(response).to render_template :new
        end
      end

      describe "when a user manages multiple enterprises suitable for coordinator" do
        let!(:distributor1) { create(:distributor_enterprise, owner: distributor_owner) }
        let!(:distributor2) { create(:distributor_enterprise, owner: distributor_owner) }
        let!(:distributor3) { create(:distributor_enterprise) }

        it "renders the set_coordinator template" do
          spree_get :new
          expect(response).to render_template :set_coordinator
        end

        describe "and a coordinator_id is submitted as part of the request" do
          describe "when the user manages the enterprise" do
            it "renders the new template" do
              spree_get :new, coordinator_id: distributor1.id
              expect(response).to render_template :new
            end
          end

          describe "when the user does not manage the enterprise" do
            it "renders the set_coordinator template and sets a flash error" do
              spree_get :new, coordinator_id: distributor3.id
              expect(response).to render_template :set_coordinator
              expect(flash[:error]).to eq "You don't have permission to create an order cycle coordinated by that enterprise"
            end
          end
        end
      end
    end

    describe "update" do
      let(:order_cycle) { create(:simple_order_cycle) }
      let(:producer) { create(:supplier_enterprise) }
      let(:coordinator) { order_cycle.coordinator }
      let(:hub) { create(:distributor_enterprise) }
      let(:v) { create(:variant) }
      let!(:incoming_exchange) { create(:exchange, order_cycle: order_cycle, sender: producer, receiver: coordinator, incoming: true, variants: [v]) }
      let!(:outgoing_exchange) { create(:exchange, order_cycle: order_cycle, sender: coordinator, receiver: hub, incoming: false, variants: [v]) }

      context "as a manager of the coordinator" do
        before { login_as_enterprise_user([coordinator]) }

        it "sets flash message when page is reloading" do
          spree_put :update, id: order_cycle.id, reloading: '1', order_cycle: {}
          flash[:notice].should == 'Your order cycle has been updated.'
        end

        it "does not set flash message otherwise" do
          flash[:notice].should be_nil
        end

        context "when updating without explicitly submitting exchanges" do
          let(:form_applicator_mock) { double(:form_applicator) }

          before do
            allow(OpenFoodNetwork::OrderCycleFormApplicator).to receive(:new) { form_applicator_mock }
            allow(form_applicator_mock).to receive(:go!) { nil }
          end

           it "does not run the OrderCycleFormApplicator" do
             expect(order_cycle.exchanges.incoming).to eq [incoming_exchange]
             expect(order_cycle.exchanges.outgoing).to eq [outgoing_exchange]
             expect(order_cycle.prefers_product_selection_from_coordinator_inventory_only?).to be false
             spree_put :update, id: order_cycle.id, order_cycle: { name: 'Some new name', preferred_product_selection_from_coordinator_inventory_only: true }
             expect(form_applicator_mock).to_not have_received(:go!)
             order_cycle.reload
             expect(order_cycle.exchanges.incoming).to eq [incoming_exchange]
             expect(order_cycle.exchanges.outgoing).to eq [outgoing_exchange]
             expect(order_cycle.name).to eq 'Some new name'
             expect(order_cycle.prefers_product_selection_from_coordinator_inventory_only?).to be true
           end
        end
      end

      context "as a producer supplying to an order cycle" do
        before do
          login_as_enterprise_user [producer]
        end

        describe "removing a variant from incoming" do
          let(:params) do
            {order_cycle: {
               incoming_exchanges: [{id: incoming_exchange.id, enterprise_id: producer.id, sender_id: producer.id, variants: {v.id => false}}],
               outgoing_exchanges: [{id: outgoing_exchange.id, enterprise_id: hub.id,      receiver_id: hub.id,    variants: {v.id => false}}] }
            }
          end

          it "removes the variant from outgoing also" do
            spree_put :update, {id: order_cycle.id}.merge(params)
            Exchange.where(order_cycle_id: order_cycle).with_variant(v).should be_empty
          end
        end
      end
    end

    describe "updating schedules" do
      let(:user) { create(:user, enterprise_limit: 10) }
      let!(:managed_coordinator) { create(:enterprise, owner: user) }
      let!(:managed_enterprise) { create(:enterprise, owner: user) }
      let!(:coordinated_order_cycle) { create(:simple_order_cycle, coordinator: managed_coordinator ) }
      let!(:coordinated_order_cycle2) { create(:simple_order_cycle, coordinator: managed_enterprise ) }
      let!(:uncoordinated_order_cycle) { create(:simple_order_cycle, coordinator: create(:enterprise) ) }
      let!(:coordinated_schedule) { create(:schedule, order_cycles: [coordinated_order_cycle] ) }
      let!(:coordinated_schedule2) { create(:schedule, order_cycles: [coordinated_order_cycle2] ) }
      let!(:uncoordinated_schedule) { create(:schedule, order_cycles: [uncoordinated_order_cycle] ) }

      context "where I manage the order_cycle's coordinator" do
        render_views

        before do
          controller.stub spree_current_user: user
        end

        it "allows me to assign only schedules that already I coordinate to the order cycle" do
          schedule_ids = [coordinated_schedule2.id, uncoordinated_schedule.id ]
          spree_put :update, format: :json, id: coordinated_order_cycle.id, order_cycle: { schedule_ids: schedule_ids }
          expect(assigns(:order_cycle)).to eq coordinated_order_cycle
          # coordinated_order_cycle2 is added
          expect(coordinated_order_cycle.reload.schedules).to include coordinated_schedule2
          # coordinated_order_cycle is removed, uncoordinated_order_cycle is NOT added
          expect(coordinated_order_cycle.reload.schedules).to_not include coordinated_schedule, uncoordinated_schedule
        end
      end
    end

    describe "bulk_update" do
      let(:oc) { create(:simple_order_cycle) }
      let!(:coordinator) { oc.coordinator }

      context "when I manage the coordinator of an order cycle" do
        before { create(:enterprise_role, user: distributor_owner, enterprise: coordinator) }

        it "updates order cycle properties" do
          spree_put :bulk_update, order_cycle_set: { collection_attributes: { '0' => {
            id: oc.id,
            orders_open_at: Date.current - 21.days,
            orders_close_at: Date.current + 21.days,
          } } }

          oc.reload
          expect(oc.orders_open_at.to_date).to eq Date.current - 21.days
          expect(oc.orders_close_at.to_date).to eq Date.current + 21.days
        end

        it "does nothing when no data is supplied" do
          expect do
            spree_put :bulk_update
          end.to change(oc, :orders_open_at).by(0)
        end
      end

      context "when I do not manage the coordinator of an order cycle" do
        # I need to manage a hub in order to access the bulk_update action
        let!(:another_distributor) { create(:distributor_enterprise, users: [distributor_owner]) }

        it "doesn't update order cycle properties" do
          spree_put :bulk_update, order_cycle_set: { collection_attributes: { '0' => {
            id: oc.id,
            orders_open_at: Date.current - 21.days,
            orders_close_at: Date.current + 21.days,
          } } }

          oc.reload
          expect(oc.orders_open_at.to_date).to_not eq Date.current - 21.days
          expect(oc.orders_close_at.to_date).to_not eq Date.current + 21.days
        end
      end
    end


    describe "notifying producers" do
      let(:user) { create_enterprise_user }
      let(:admin_user) do
        user = create(:user)
        user.spree_roles << Spree::Role.find_or_create_by_name!('admin')
        user
      end
      let(:order_cycle) { create(:simple_order_cycle) }

      before do
        controller.stub spree_current_user: admin_user
      end

      it "enqueues a job" do
        expect do
          spree_post :notify_producers, {id: order_cycle.id}
        end.to enqueue_job OrderCycleNotificationJob
      end

      it "redirects back to the order cycles path with a success message" do
        spree_post :notify_producers, {id: order_cycle.id}
        expect(response).to redirect_to admin_order_cycles_path
        flash[:notice].should == 'Emails to be sent to producers have been queued for sending.'
      end
    end


    describe "destroy" do
      let!(:distributor) { create(:distributor_enterprise, owner: distributor_owner) }

      describe "when an order cycle becomes non-deletable, and we attempt to delete it" do
        let!(:oc)    { create(:simple_order_cycle, coordinator: distributor) }
        let!(:order) { create(:order, order_cycle: oc) }

        before { spree_get :destroy, id: oc.id }

        it "displays an error message" do
          expect(response).to redirect_to admin_order_cycles_path
          expect(flash[:error]).to eq "That order cycle has been selected by a customer and cannot be deleted. To prevent customers from accessing it, please close it instead."
        end
      end
    end
  end
end
