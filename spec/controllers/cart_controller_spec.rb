require 'spec_helper'
require 'spree/api/testing_support/helpers'

module OpenFoodNetwork
  describe CartController, type: :controller do
    render_views

    let(:user) { FactoryGirl.create(:user) }
    let(:product1) do
      p1 = FactoryGirl.create(:product)
      p1.update_column(:count_on_hand, 10)
      p1
    end
    let(:cart) { Cart.create(user: user) }
    let(:distributor) { FactoryGirl.create(:distributor_enterprise) }

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

        context 'with an empty order' do
          let(:order) { FactoryGirl.create(:order, distributor: distributor) }

          before(:each) do
            cart.orders << order
            cart.save!
          end

          it "retrieves a cart with a single order and line item" do
            get :show, {id: cart, :format => :json }
            json_response = JSON.parse(response.body)

            json_response['orders'].size.should == 1
            json_response['orders'].first['distributor'].should == order.distributor.name
            json_response['orders'].first['line_items'].size.should == 0
          end
        end

        context 'an order with line items' do
          let(:product) { FactoryGirl.create(:product, distributors: [ distributor ]) }
          let(:order) { FactoryGirl.create(:order, { distributor: distributor } ) }
          let(:line_item) { FactoryGirl.create(:line_item, { variant: product.master }) }

          before(:each) do
            order.line_items << line_item
            order.save
            cart.orders << order
            cart.save!
          end

          it "retrieves a cart with a single order and line item" do
            get :show, {id: cart, :format => :json }
            json_response = JSON.parse(response.body)

            json_response['orders'].size.should == 1
            json_response['orders'].first['distributor'].should == order.distributor.name
            json_response['orders'].first['line_items'].first["name"].should == product.name
            json_response['orders'].first['line_items'].first["quantity"].should == line_item.quantity
          end
        end

        context 'adding a variant' do

          it 'should add variant to new order and return the order' do
            product1.distributors << distributor
            product1.save
            variant = product1.variants.first

            put :add_variant, { cart_id: cart, variant_id: variant.id, quantity: (variant.on_hand-1), distributor_id: distributor, order_cycle_id: nil, max_quantity: nil }

            cart.orders.size.should == 1
            cart.orders.first.line_items.size.should == 1
            cart.orders.first.line_items.first.product.should == product1
          end
        end
      end
    end
  end
end
