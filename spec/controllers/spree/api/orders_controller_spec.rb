require 'spec_helper'
require 'spree/api/testing_support/helpers'

module Spree
  describe Spree::Api::OrdersController do
    include Spree::Api::TestingSupport::Helpers
    render_views
    
    
    let!(:order1) { FactoryGirl.create(:order) }
    let!(:line_item1) { FactoryGirl.create(:line_item) }
    let!(:line_item2) { FactoryGirl.create(:line_item) }
    let(:attributes) { [:id] }

    before do
      stub_authentication!
      Spree.user_class.stub :find_by_spree_api_key => current_api_user
    end

    context "as a normal user" do
      it "retrieves a list of products with appropriate attributes" do
        spree_get :index, { :template => 'bulk_index', :format => :json }
        keys = json_response.first.keys.map{ |key| key.to_sym }
        attributes.all?{ |attr| keys.include? attr }.should == true
      end
    end
  end
end