require 'spec_helper'

# TODO this seems to be redundant
describe Cart do

  describe "associations" do
    it { should have_many(:orders) }
  end

  describe 'when adding a product' do

    let(:cart) { Cart.create(user: user) }
    let(:distributor) { FactoryGirl.create(:distributor_enterprise) }
    let(:other_distributor) { FactoryGirl.create(:distributor_enterprise) }
    let(:currency) { "AUD" }

    let(:product) { FactoryGirl.create(:product, :distributors => [distributor]) }

    let(:product_with_order_cycle) { create(:product) }
    let(:order_cycle) { create(:simple_order_cycle, distributors: [distributor, other_distributor], variants: [product_with_order_cycle.master]) }

    describe 'to an empty cart' do
      it 'should create an order for the product being added, and associate the product to the selected distribution' do
        subject.add_variant product.master.id, 3, distributor, nil, currency

        subject.orders.size.should == 1
        order = subject.orders.first.reload
        order.currency.should == currency
        order.distributor.should == product.distributors.first
        order.order_cycle.should be_nil
        order.line_items.first.product.should == product
      end

      it 'should create an order for the product being added, and associate the order with an order cycle and distributor' do
        subject.add_variant product_with_order_cycle.master.id, 3, distributor, order_cycle, currency

        subject.orders.size.should == 1
        order = subject.orders.first.reload
        order.currency.should == currency
        order.distributor.should == distributor
        order.order_cycle.should == order_cycle
        order.line_items.first.product.should == product_with_order_cycle
      end
    end

    describe 'to a cart with an order for a distributor' do
      let(:product_from_other_distributor) { FactoryGirl.create(:product, :distributors => [other_distributor]) }
      let(:order) { FactoryGirl.create(:order, :distributor => distributor) }

      before do
        FactoryGirl.create(:line_item, :order => order, :product => product)
        order.reload
        subject.orders << order
        subject.save!
      end

      it 'should create a new order and add a line item to it when product added for different distributor' do
        subject.add_variant product_from_other_distributor.master.id, 3, other_distributor, nil, currency

        subject.reload
        subject.orders.size.should == 2
        new_order_for_other_distributor = subject.orders.find { |order| order.distributor == other_distributor }
        new_order_for_other_distributor.order_cycle.should be_nil
        order.line_items.size.should == 1
        new_order_for_other_distributor.line_items.size.should == 1
        new_order_for_other_distributor.line_items.first.product.should == product_from_other_distributor
      end

      it 'should group line item in existing order, when product added for the same distributor' do
        subject.add_variant product.master.id, 3, distributor, nil, currency

        subject.orders.size.should == 1
        order = subject.orders.first.reload
        order.line_items.size.should == 2
        order.line_items.first.product.should == product
      end

      it 'should create a new order for product in an order cycle' do
        subject.add_variant product_with_order_cycle.master.id, 3, distributor, order_cycle, currency

        subject.orders.size.should == 2
        new_order_for_distributor = subject.orders.find { |order| order.order_cycle == order_cycle }
        new_order_for_distributor.reload
        new_order_for_distributor.line_items.first.product.should == product_with_order_cycle
      end
    end

    describe 'existing order for distributor and order cycle' do
      let(:order) { FactoryGirl.create(:order, :distributor => distributor, :order_cycle => order_cycle) }

      before do
        subject.orders << order
        subject.save!
      end

      it 'should group line items in existing order when added for the same distributor and order cycle' do
        subject.add_variant product_with_order_cycle.master.id, 3, distributor, order_cycle, currency

        subject.orders.size.should == 1
        order = subject.orders.first.reload
        order.line_items.size.should == 1
        order.line_items.find{ |line_item| line_item.product == product_with_order_cycle }.should_not be_nil
      end

      it 'should create line item in new order when product added is for a different order cycle' do
        order_cycle2 = create(:simple_order_cycle, distributors: [distributor], variants: [product_with_order_cycle.master])

        subject.add_variant product_with_order_cycle.master.id, 3, distributor, order_cycle2, currency

        subject.orders.size.should == 2
        new_order_for_second_order_cycle = subject.orders.find { |order| order.order_cycle == order_cycle2 }
        new_order_for_second_order_cycle.reload
        new_order_for_second_order_cycle.line_items.size.should == 1
        new_order_for_second_order_cycle.line_items.first.product.should == product_with_order_cycle
        new_order_for_second_order_cycle.distributor.should == distributor
        new_order_for_second_order_cycle.order_cycle.should == order_cycle2
      end

      it 'should create line_items in new order when added with different distributor, but same order_cycle' do
        subject.add_variant product_with_order_cycle.master.id, 3, other_distributor, order_cycle, currency

        subject.orders.size.should == 2
        new_order_for_second_order_cycle = subject.orders.find { |order| order.distributor == other_distributor }
        new_order_for_second_order_cycle.reload
        new_order_for_second_order_cycle.line_items.size.should == 1
        new_order_for_second_order_cycle.line_items.find{ |line_item| line_item.product == product_with_order_cycle }.should_not be_nil
        new_order_for_second_order_cycle.order_cycle.should == order_cycle
      end
    end
  end
end
