require 'spec_helper'
require 'spree/api/testing_support/helpers'

describe CartController do
  include Spree::Api::TestingSupport::Helpers
  render_views

  let(:current_api_user) { stub_model(Spree.user_class, :email => "spree@example.com") }
  let!(:product1) { FactoryGirl.create(:product) }
  let!(:cart) { Cart.create(user: current_api_user) }

  before do
    stub_authentication!
    Spree.user_class.stub :find_by_spree_api_key => current_api_user
  end

  context "as a normal user" do


    context 'with an existing cart' do

      it "retrieves an empty cart" do
        spree_get :show, {id: cart, :format => :json }

        json_response["id"].should == cart.id
        json_response['orders'].size.should == 0
      end

      context 'with an order' do

        let(:order) { FactoryGirl.create(:order_with_totals_and_distributor) }

        before(:each) do
          cart.orders << order
          cart.save!
        end

        it "retrieves a cart with a single order and line item" do
          spree_get :show, {id: cart, :format => :json }

          json_response['orders'].size.should == 1
          json_response['orders'].first['distributor'].should == order.distributor.name
        end
      end
    end
  end
end
