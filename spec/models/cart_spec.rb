require 'spec_helper'

# TODO this seems to be redundant
describe Cart do

  describe "associations" do
    it { is_expected.to have_many(:orders) }
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

        expect(subject.orders.size).to eq(1)
        order = subject.orders.first.reload
        expect(order.currency).to eq(currency)
        expect(order.distributor).to eq(product.distributors.first)
        expect(order.order_cycle).to be_nil
        expect(order.line_items.first.product).to eq(product)
      end

      it 'should create an order for the product being added, and associate the order with an order cycle and distributor' do
        subject.add_variant product_with_order_cycle.master.id, 3, distributor, order_cycle, currency

        expect(subject.orders.size).to eq(1)
        order = subject.orders.first.reload
        expect(order.currency).to eq(currency)
        expect(order.distributor).to eq(distributor)
        expect(order.order_cycle).to eq(order_cycle)
        expect(order.line_items.first.product).to eq(product_with_order_cycle)
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
        expect(subject.orders.size).to eq(2)
        new_order_for_other_distributor = subject.orders.find { |order| order.distributor == other_distributor }
        expect(new_order_for_other_distributor.order_cycle).to be_nil
        expect(order.line_items.size).to eq(1)
        expect(new_order_for_other_distributor.line_items.size).to eq(1)
        expect(new_order_for_other_distributor.line_items.first.product).to eq(product_from_other_distributor)
      end

      it 'should group line item in existing order, when product added for the same distributor' do
        subject.add_variant product.master.id, 3, distributor, nil, currency

        expect(subject.orders.size).to eq(1)
        order = subject.orders.first.reload
        expect(order.line_items.size).to eq(2)
        expect(order.line_items.first.product).to eq(product)
      end

      it 'should create a new order for product in an order cycle' do
        subject.add_variant product_with_order_cycle.master.id, 3, distributor, order_cycle, currency

        expect(subject.orders.size).to eq(2)
        new_order_for_distributor = subject.orders.find { |order| order.order_cycle == order_cycle }
        new_order_for_distributor.reload
        expect(new_order_for_distributor.line_items.first.product).to eq(product_with_order_cycle)
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

        expect(subject.orders.size).to eq(1)
        order = subject.orders.first.reload
        expect(order.line_items.size).to eq(1)
        expect(order.line_items.find{ |line_item| line_item.product == product_with_order_cycle }).not_to be_nil
      end

      it 'should create line item in new order when product added is for a different order cycle' do
        order_cycle2 = create(:simple_order_cycle, distributors: [distributor], variants: [product_with_order_cycle.master])

        subject.add_variant product_with_order_cycle.master.id, 3, distributor, order_cycle2, currency

        expect(subject.orders.size).to eq(2)
        new_order_for_second_order_cycle = subject.orders.find { |order| order.order_cycle == order_cycle2 }
        new_order_for_second_order_cycle.reload
        expect(new_order_for_second_order_cycle.line_items.size).to eq(1)
        expect(new_order_for_second_order_cycle.line_items.first.product).to eq(product_with_order_cycle)
        expect(new_order_for_second_order_cycle.distributor).to eq(distributor)
        expect(new_order_for_second_order_cycle.order_cycle).to eq(order_cycle2)
      end

      it 'should create line_items in new order when added with different distributor, but same order_cycle' do
        subject.add_variant product_with_order_cycle.master.id, 3, other_distributor, order_cycle, currency

        expect(subject.orders.size).to eq(2)
        new_order_for_second_order_cycle = subject.orders.find { |order| order.distributor == other_distributor }
        new_order_for_second_order_cycle.reload
        expect(new_order_for_second_order_cycle.line_items.size).to eq(1)
        expect(new_order_for_second_order_cycle.line_items.find{ |line_item| line_item.product == product_with_order_cycle }).not_to be_nil
        expect(new_order_for_second_order_cycle.order_cycle).to eq(order_cycle)
      end
    end
  end
end
