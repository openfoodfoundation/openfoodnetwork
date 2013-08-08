require 'spec_helper'
require 'spree/api/testing_support/helpers'

module OpenFoodWeb
  describe CartController do
    render_views

    let(:user) { FactoryGirl.create(:user) }
    let(:product1) { FactoryGirl.create(:product) }
    let(:cart) { Cart.create(user: user) }

    before do
    end

    context "as a normal user" do

      context 'with an existing cart' do

        it "retrieves an empty cart" do
          get :show, {id: cart, :format => :json }
          json_response = JSON.parse(response.body)

          json_response['id'].should == cart.id
          json_response['orders'].size.should == 0
        end

        context 'with an order' do

          let(:order) { FactoryGirl.create(:order_with_totals_and_distributor) }

          before(:each) do
            cart.orders << order
            cart.save!
          end

          it "retrieves a cart with a single order and line item" do
            get :show, {id: cart, :format => :json }
            json_response = JSON.parse(response.body)

            json_response['orders'].size.should == 1
            json_response['orders'].first['distributor'].should == order.distributor.name
          end
        end
      end
    end
  end
end