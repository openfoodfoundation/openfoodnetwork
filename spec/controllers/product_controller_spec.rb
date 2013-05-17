require 'spec_helper'
require 'spree/core/testing_support/authorization_helpers'
require 'pry'

describe Spree::Admin::ProductsController do
  stub_authorization!
  render_views
    
  context "bulk index" do 
    let(:ability_user) { stub_model(Spree::LegacyUser, :has_spree_role? => true) }
    
    it "stores the list of products in a collection" do
      p1 = FactoryGirl.create(:product)
      p2 = FactoryGirl.create(:product)
      spree_get :bulk_index, { format: :json }
      #process :bulk_index, {:use_route=> :spree}, nil, nil, "GET"
      
      assigns[:collection].should_not be_empty
      assigns[:collection].should == [ p1, p2 ]
    end
    
    it "collects returns products in an array formatted as json" do
      p1 = FactoryGirl.create(:product)
      p2 = FactoryGirl.create(:product)
      spree_get :bulk_index, { format: :json }
      
      p1r = {
        "id" => p1.id,
        "name" => p1.name,
        "supplier_id" => p1.supplier_id,
        "available_on" => p1.available_on.strftime("%F %T"),
        "master" => {
          "id" => p1.master.id,
          "price" => p1.master.price.to_s
        }
      }
      p2r = {
        "id" => p2.id,
        "name" => p2.name,
        "supplier_id" => p2.supplier_id,
        "available_on" => p2.available_on.strftime("%F %T"),
        "master" => {
          "id" => p2.master.id,
          "price" => p2.master.price.to_s
        }
      }
      json_response = JSON.parse(response.body)
      #json_response = Hash[json_response.map{ |k, v| [k.to_sym, v] }]
      json_response.should == [ p1r, p2r ]
    end
  end
end