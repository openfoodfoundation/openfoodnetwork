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
      
      assigns[:collection].should_not be_empty
      assigns[:collection].should == [ p1, p2 ]
    end
    
    it "collects returns products in an array formatted as json" do
      p1 = FactoryGirl.create(:product)
      p2 = FactoryGirl.create(:product)
      v11 = FactoryGirl.create(:variant, product: p1, on_hand: 1)
      v12 = FactoryGirl.create(:variant, product: p1, on_hand: 2)
      v13 = FactoryGirl.create(:variant, product: p1, on_hand: 3)
      v21 = FactoryGirl.create(:variant, product: p2, on_hand: 4)
      spree_get :bulk_index, { format: :json }
      
      p1r = {
        "id" => p1.id,
        "name" => p1.name,
        "supplier" => {
          "id" => p1.supplier_id,
          "name" => p1.supplier.name
        },
        "available_on" => p1.available_on.strftime("%F %T"),
        "price" => p1.price.to_s,
        "on_hand" => ( v11.on_hand + v12.on_hand + v13.on_hand ),
        "variants" => [ #ordered by id
          { "id" => v11.id, "options_text" => v11.options_text, "price" => v11.price.to_s, "on_hand" => v11.on_hand },
          { "id" => v12.id, "options_text" => v12.options_text, "price" => v12.price.to_s, "on_hand" => v12.on_hand },
          { "id" => v13.id, "options_text" => v13.options_text, "price" => v13.price.to_s, "on_hand" => v13.on_hand }
        ],
        "permalink_live" => p1.permalink
      }
      p2r = {
        "id" => p2.id,
        "name" => p2.name,
        "supplier" => {
          "id" => p2.supplier_id,
          "name" => p2.supplier.name
        },
        "available_on" => p2.available_on.strftime("%F %T"),
        "price" => p2.price.to_s,
        "on_hand" => v21.on_hand,
        "variants" => [ #ordered by id
          { "id" => v21.id, "options_text" => v21.options_text, "price" => v21.price.to_s, "on_hand" => v21.on_hand  }
        ],
        "permalink_live" => p2.permalink
      }
      json_response = JSON.parse(response.body)
      json_response.should == [ p1r, p2r ]
    end
  end

  context "cloning a product" do
    let(:ability_user) { stub_model(Spree::LegacyUser, :has_spree_role? => true) }

    it "renders the newly created product as json" do
      p1 = FactoryGirl.create(:product)
      p2 = FactoryGirl.create(:product)

      spree_get :clone, { :format => :json, :id => p1.permalink }

      json_response = JSON.parse(response.body)
      json_response.keys.should == ["product"]
      json_response["product"]["id"].should_not == p1.id;
      json_response["product"]["name"].should == "COPY OF #{p1.name}";
      json_response["product"]["available_on"].should == p1.available_on.strftime("%FT%TZ");
      json_response["product"]["supplier_id"].should == p1.supplier_id;
    end
  end
end