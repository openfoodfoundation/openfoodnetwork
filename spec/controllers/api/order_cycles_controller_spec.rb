require 'spec_helper'
require 'spree/api/testing_support/helpers'

module Api
  describe OrderCyclesController, type: :controller do
    include Spree::Api::TestingSupport::Helpers
    include AuthenticationWorkflow
    render_views

    describe "managed" do
      let!(:oc1) { FactoryGirl.create(:simple_order_cycle) }
      let!(:oc2) { FactoryGirl.create(:simple_order_cycle) }
      let(:coordinator) { oc1.coordinator }
      let(:attributes) { [:id, :name, :suppliers, :distributors] }

      before do
        allow(controller).to receive(:spree_current_user) { current_api_user }
      end

      context "as a normal user" do
        sign_in_as_user!

        it "should deny me access to managed order cycles" do
          spree_get :managed, { :format => :json }
          assert_unauthorized!
        end
      end

      context "as an enterprise user" do
        sign_in_as_enterprise_user! [:coordinator]

        it "retrieves a list of variants with appropriate attributes" do
          get :managed, { :format => :json }
          keys = json_response.first.keys.map{ |key| key.to_sym }
          attributes.all?{ |attr| keys.include? attr }.should == true
        end
      end

      context "as an administrator" do
        sign_in_as_admin!

        it "retrieves a list of variants with appropriate attributes" do
          get :managed, { :format => :json }
          keys = json_response.first.keys.map{ |key| key.to_sym }
          attributes.all?{ |attr| keys.include? attr }.should == true
        end
      end
    end

    describe "accessible" do
      context "without :as parameter" do
        let(:oc_supplier) { create(:supplier_enterprise) }
        let(:oc_distributor) { create(:distributor_enterprise) }
        let(:other_supplier) { create(:supplier_enterprise) }
        let(:oc_supplier_user) do
          user = create(:user)
          user.spree_roles = []
          user.enterprise_roles.create(enterprise: oc_supplier)
          user.save!
          user
        end
        let(:oc_distributor_user) do
          user = create(:user)
          user.spree_roles = []
          user.enterprise_roles.create(enterprise: oc_distributor)
          user.save!
          user
        end
        let(:other_supplier_user) do
          user = create(:user)
          user.spree_roles = []
          user.enterprise_roles.create(enterprise: other_supplier)
          user.save!
          user
        end
        let!(:order_cycle) { create(:simple_order_cycle, suppliers: [oc_supplier], distributors: [oc_distributor]) }

        context "as the user of a supplier to an order cycle" do
          before do
            allow(controller).to receive(:spree_current_user) { oc_supplier_user }
          end

          it "gives me access" do
            spree_get :accessible, { :template => 'bulk_index', :format => :json }

            json_response.length.should == 1
            json_response[0]['id'].should == order_cycle.id
          end
        end

        context "as the user of some other supplier" do
          before do
            allow(controller).to receive(:spree_current_user) { other_supplier_user }
          end

          it "does not give me access" do
            spree_get :accessible, { :template => 'bulk_index', :format => :json }
            json_response.length.should == 0
          end
        end

        context "as the user of a hub for the order cycle" do
          before do
            allow(controller).to receive(:spree_current_user) { oc_distributor_user }
          end

          it "gives me access" do
            spree_get :accessible, { :template => 'bulk_index', :format => :json }

            json_response.length.should == 1
            json_response[0]['id'].should == order_cycle.id
          end
        end
      end

      context "when the :as parameter is set to 'distributor'" do
        let(:user) { create_enterprise_user }
        let(:distributor) { create(:distributor_enterprise) }
        let(:producer) { create(:supplier_enterprise) }
        let(:coordinator) { create(:distributor_enterprise) }
        let!(:oc) { create(:simple_order_cycle, coordinator: coordinator, distributors: [distributor], suppliers: [producer]) }

        let(:params) { { format: :json, as: 'distributor' } }

        before do
          allow(controller).to receive(:spree_current_user) { user }
        end

        context "as the manager of a supplier in an order cycle" do
          before { user.enterprise_roles.create(enterprise: producer) }

          it "does not return the order cycle" do
            spree_get :accessible, params
            expect(assigns(:order_cycles)).to_not include oc
          end
        end

        context "as the manager of a distributor in an order cycle" do
          before { user.enterprise_roles.create(enterprise: distributor) }

          it "returns the order cycle" do
            spree_get :accessible, params
            expect(assigns(:order_cycles)).to include oc
          end
        end

        context "as the manager of the coordinator of an order cycle" do
          before { user.enterprise_roles.create(enterprise: coordinator) }

          it "returns the order cycle" do
            spree_get :accessible, params
            expect(assigns(:order_cycles)).to include oc
          end
        end
      end

      context "when the :as parameter is set to 'producer'" do
        let(:user) { create_enterprise_user }
        let(:distributor) { create(:distributor_enterprise) }
        let(:producer) { create(:supplier_enterprise) }
        let(:coordinator) { create(:distributor_enterprise) }
        let!(:oc) { create(:simple_order_cycle, coordinator: coordinator, distributors: [distributor], suppliers: [producer]) }

        let(:params) { { format: :json, as: 'producer' } }

        before do
          allow(controller).to receive(:spree_current_user) { user }
        end

        context "as the manager of a producer in an order cycle" do
          before { user.enterprise_roles.create(enterprise: producer) }

          it "returns the order cycle" do
            spree_get :accessible, params
            expect(assigns(:order_cycles)).to include oc
          end
        end

        context "as the manager of a distributor in an order cycle" do
          before { user.enterprise_roles.create(enterprise: distributor) }

          it "does not return the order cycle" do
            spree_get :accessible, params
            expect(assigns(:order_cycles)).to_not include oc
          end
        end

        context "as the manager of the coordinator of an order cycle" do
          before { user.enterprise_roles.create(enterprise: coordinator) }

          it "returns the order cycle" do
            spree_get :accessible, params
            expect(assigns(:order_cycles)).to include oc
          end
        end
      end
    end
  end
end
