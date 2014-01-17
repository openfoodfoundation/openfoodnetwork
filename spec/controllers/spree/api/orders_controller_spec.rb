require 'spec_helper'
require 'spree/api/testing_support/helpers'

module Spree
  describe Spree::Api::OrdersController do
    include Spree::Api::TestingSupport::Helpers
    render_views
    
    let!(:order1) { FactoryGirl.create(:order, :state => 'complete', :completed_at => Time.now ) }
    let!(:order2) { FactoryGirl.create(:order, :state => 'complete', :completed_at => Time.now ) }
    let!(:order3) { FactoryGirl.create(:order, :state => 'complete', :completed_at => Time.now ) }
    let!(:line_item1) { FactoryGirl.create(:line_item, :order => order1) }
    let!(:line_item2) { FactoryGirl.create(:line_item, :order => order2) }
    let!(:line_item3) { FactoryGirl.create(:line_item, :order => order2) }
    let!(:line_item4) { FactoryGirl.create(:line_item, :order => order3) }
    let(:order_attributes) { [:id, :email, :completed_at, :line_items] }
    let(:line_item_attributes) { [:id, :quantity, :max_quantity, :supplier, :variant_unit_text] }

    before do
      stub_authentication!
      Spree.user_class.stub :find_by_spree_api_key => current_api_user
    end

    context "as a normal user" do
      before :each do
        spree_get :index, { :template => 'bulk_index', :format => :json }
      end

      it "retrieves a list of orders with appropriate attributes, including line items with appropriate attributes" do
        keys = json_response.first.keys.map{ |key| key.to_sym }
        order_attributes.all?{ |attr| keys.include? attr }.should == true
      end

      it "retrieves a list of line items with appropriate attributes" do
        li_keys = json_response.first['line_items'].first.keys.map{ |key| key.to_sym }
        line_item_attributes.all?{ |attr| li_keys.include? attr }.should == true
      end

      it "sorts orders in ascending id order" do
        ids = json_response.map{ |order| order['id'] }
        ids[0].should < ids[1]
        ids[1].should < ids[2]
      end

      it "formats completed_at to 'yyyy-mm-dd hh:mm'" do
        json_response.map{ |order| order['completed_at'] }.all?{ |a| a.match("^\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}:\\d{2}$") }.should == true
      end
    end
  end
end