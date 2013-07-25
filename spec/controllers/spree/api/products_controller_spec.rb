require 'spec_helper'
require 'spree/api/testing_support/helpers'

module Spree
  describe Spree::Api::ProductsController do
    include Spree::Api::TestingSupport::Helpers
    render_views

    let!(:product1) { FactoryGirl.create(:product) }
    let!(:product2) { FactoryGirl.create(:product) }
    let!(:product3) { FactoryGirl.create(:product) }
    let(:attributes) { [:id, :name, :supplier, :price, :on_hand, :available_on, :permalink_live] }

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

      it "sorts products in ascending id order" do
        spree_get :index, { :template => 'bulk_index', :format => :json }
        ids = json_response.map{ |product| product['id'] }
        ids[0].should < ids[1]
        ids[1].should < ids[2]
      end

      it "formats available_on to 'yyyy-mm-dd hh:mm'" do
        spree_get :index, { :template => 'bulk_index', :format => :json }
        json_response.map{ |product| product['available_on'] }.all?{ |a| a.match("^\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}:\\d{2}$") }.should == true
      end

      it "returns permalink as permalink_live" do
        spree_get :index, { :template => 'bulk_index', :format => :json }
        json_response.detect{ |product| product['id'] == product1.id }['permalink_live'].should == product1.permalink
      end

      it "should allow available_on to be nil" do
        product4 = FactoryGirl.create(:product)
        product4.available_on = nil
        product4.save!

        spree_get :index, { :template => 'bulk_index', :format => :json }
        json_response.size.should == 4
      end
    end
  end
end