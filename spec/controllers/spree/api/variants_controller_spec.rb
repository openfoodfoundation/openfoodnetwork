require 'spec_helper'
require 'spree/api/testing_support/helpers'

module Spree
  describe Spree::Api::VariantsController do
    include Spree::Api::TestingSupport::Helpers
    render_views
    
    let!(:variant1) { FactoryGirl.create(:variant) }
    let!(:variant2) { FactoryGirl.create(:variant) }
    let!(:variant3) { FactoryGirl.create(:variant) }
    let(:attributes) { [:id, :options_text, :price, :on_hand] }
    let(:unit_attributes) { [:id, :unit_text, :unit_value] }

    before do
      stub_authentication!
      Spree.user_class.stub :find_by_spree_api_key => current_api_user
    end

    context "as a normal user" do
      it "retrieves a list of variants with appropriate attributes" do
        spree_get :index, { :template => 'bulk_index', :format => :json }
        keys = json_response.first.keys.map{ |key| key.to_sym }
        attributes.all?{ |attr| keys.include? attr }.should == true
      end

      it "retrieves a list of variants with attributes relating to units" do
        spree_get :show, { :id => variant1.id, :template => "units_show", :format => :json }
        keys = json_response.keys.map{ |key| key.to_sym }
        unit_attributes.all?{ |attr| keys.include? attr }.should == true
      end
      #it "sorts variants in ascending id order" do
      #  spree_get :index, { :template => 'bulk_index', :format => :json }
      #  ids = json_response.map{ |variant| variant['id'] }
      #  ids[0].should < ids[1]
      #  ids[1].should < ids[2]
      #end
    end
  end
end