require 'spec_helper'
require 'spree/api/testing_support/helpers'

module Api
  describe OrderCyclesController do
    include Spree::Api::TestingSupport::Helpers
    render_views

    let!(:oc1) { FactoryGirl.create(:order_cycle) }
    let!(:oc2) { FactoryGirl.create(:order_cycle) }
    let(:attributes) { [:id, :name, :suppliers, :distributors] }

    before do
      stub_authentication!
      Spree.user_class.stub :find_by_spree_api_key => current_api_user
    end

    context "as a normal user" do
      it "retrieves a list of variants with appropriate attributes" do
        get :managed, { :format => :json }
        keys = json_response.first.keys.map{ |key| key.to_sym }
        attributes.all?{ |attr| keys.include? attr }.should == true
      end
    end
  end
end