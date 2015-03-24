require 'spec_helper'

module Admin
  describe OrderCyclesController do
    include AuthenticationWorkflow
    let!(:distributor_owner) { create_enterprise_user enterprise_limit: 2 }

    before do
      controller.stub spree_current_user: distributor_owner
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
