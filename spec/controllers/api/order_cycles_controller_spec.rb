require 'spec_helper'
require 'spree/api/testing_support/helpers'

module Api
  describe OrderCyclesController do
    include Spree::Api::TestingSupport::Helpers
    render_views

    context "as a normal user" do
      let!(:oc1) { FactoryGirl.create(:order_cycle) }
      let!(:oc2) { FactoryGirl.create(:order_cycle) }
      let(:attributes) { [:id, :name, :suppliers, :distributors] }

      before do
        stub_authentication!
        Spree.user_class.stub :find_by_spree_api_key => current_api_user
      end

      it "retrieves a list of variants with appropriate attributes" do
        get :managed, { :format => :json }
        keys = json_response.first.keys.map{ |key| key.to_sym }
        attributes.all?{ |attr| keys.include? attr }.should == true
      end
    end

    context "using the accessible action to list order cycles" do
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
      let!(:order_cycle) { create(:order_cycle, suppliers: [oc_supplier], distributors: [oc_distributor]) }

      context "as the user of a supplier to an order cycle" do
        before :each do
          stub_authentication!
          Spree.user_class.stub :find_by_spree_api_key => oc_supplier_user
          spree_get :accessible, { :template => 'bulk_index', :format => :json }
        end

        it "gives me access" do
          json_response.length.should == 1
          json_response[0]['id'].should == order_cycle.id
        end
      end

      context "as the user of some other supplier" do
        before :each do
          stub_authentication!
          Spree.user_class.stub :find_by_spree_api_key => other_supplier_user
          spree_get :accessible, { :template => 'bulk_index', :format => :json }
        end

        it "does not give me access" do
          json_response.length.should == 0
        end
      end

      context "as the user of a hub for the order cycle" do
        before :each do
          stub_authentication!
          Spree.user_class.stub :find_by_spree_api_key => oc_distributor_user
          spree_get :accessible, { :template => 'bulk_index', :format => :json }
        end

        it "gives me access" do
          json_response.length.should == 1
          json_response[0]['id'].should == order_cycle.id
        end
      end
    end
  end
end