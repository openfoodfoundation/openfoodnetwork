require 'spec_helper'

describe Cart do

  describe "associations" do
    it { should have_many(:orders) }
  end

  describe 'adding a product' do

    let(:cart) { Cart.create(user: user) }
    let(:distributor) { FactoryGirl.create(:distributor_enterprise) }
    let(:other_distributor) { FactoryGirl.create(:distributor_enterprise) }
    let(:currency) { "AUD" }
    let(:product) { FactoryGirl.create(:product, :distributors => [distributor]) }
    let(:product_from_other_distributor) { FactoryGirl.create(:product, :distributors => [other_distributor]) }


    describe 'to an empty cart' do
      it 'when there are no orders in the cart, create one when a product is added' do
        subject.add_variant product.master.id, 3, currency

        subject.orders.size.should == 1
        order = subject.orders.first.reload
        order.currency.should == currency
        order.line_items.first.product.should == product
      end
    end

    describe 'to a cart with an established order' do
      let(:order) { FactoryGirl.create(:order, :distributor => other_distributor) }

      before (:each) do
        subject.orders << order
        subject.save!
      end

      it 'should create an order when a product from a new distributor is added' do
        subject.add_variant product.master.id, 3, currency

        subject.reload
        subject.orders.size.should == 2
        new_order_for_distributor = subject.orders.find { |order| order.distributor == distributor }
        new_order_for_distributor.line_items.first.product.should == product
      end

      it 'should group line item in existing order, when product from the same distributor' do
        subject.add_variant product_from_other_distributor.master.id, 3, currency

        subject.orders.size.should == 1
        order = subject.orders.first.reload
        order.line_items.size.should == 1
      end

      it 'should create a line item in each order for a product that has multiple distributors' do
        product.distributors << other_distributor
        product.save!

        subject.add_variant product.master.id, 3, currency

        subject.orders.size.should == 2
        first_order = subject.orders.first.reload
        second_order = subject.orders[1].reload
        first_order.line_items.first.product.should == product
        second_order.line_items.first.product.should == product
      end

      it 'should create multiple line items for an order that has multiple order cycles'

    end

    describe 'products with order cycles' do
      let(:order_cycle) { FactoryGirl.create :order_cycle }

      before(:each) do
        product.order_cycles << order_cycle
        product.save!
      end

      it 'should create an order when a product from a new order cycle is added' do
        subject.add_variant product.master.id, 3, currency

        subject.orders.size.should == 1
        subject.orders.first.order_cycle.should == order_cycle
      end

      it 'should create line items in an order for added product, when in the same distributor and order cycle'

      it 'should not create line items in an order, if the product is in a different order cycle to the order'

      it 'should not create line items in an order, if the product is in a different distributor to the order'
    end
  end
end
