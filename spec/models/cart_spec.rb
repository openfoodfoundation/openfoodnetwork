require 'spec_helper'

describe Cart do

  describe "associations" do
    it { should have_many(:orders) }
  end

  describe 'adding a product' do

    let(:product) { create(:product) }

    it 'when there are no orders in the cart, create one when a product is added' do
      subject.add_variant product.master, 3

      subject.orders.size.should == 1
      subject.orders.first.line_items.first.product.should == product
    end

    it 'should create an order when a product from a new distributor is added'

    it 'should create an order when a product from a new order cycle is added'

    it 'should create line items in an order for added product, when in the same distributor'

    it 'should create line items in an order for added product, when in the same distributor and order cycle'

    it 'should not create line items in an order, if the product is in a different order cycle to the order'

    it 'should not create line items in an order, if the product is in a different distributor to the order'
  end
end
