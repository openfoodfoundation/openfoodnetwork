require 'spec_helper'

describe Spree::Admin::ReportsController, type: :controller do

  # Given two distributors and two suppliers
  let(:ba) { create(:address) }
  let(:sa) { create(:address) }
  let(:si) { "pick up on thursday please" }
  let(:c1) { create(:distributor_enterprise) }
  let(:c2) { create(:distributor_enterprise) }
  let(:s1) { create(:supplier_enterprise) }
  let(:s2) { create(:supplier_enterprise) }
  let(:s3) { create(:supplier_enterprise) }
  let(:d1) { create(:distributor_enterprise) }
  let(:d2) { create(:distributor_enterprise) }
  let(:d3) { create(:distributor_enterprise) }
  let(:p1) { create(:product, price: 12.34, distributors: [d1], supplier: s1) }
  let(:p2) { create(:product, price: 23.45, distributors: [d2], supplier: s2) }
  let(:p3) { create(:product, price: 34.56, distributors: [d3], supplier: s3) }

  # Given two order cycles with both distributors
  let(:ocA) { create(:simple_order_cycle, coordinator: c1, distributors: [d1, d2], suppliers: [s1, s2, s3], variants: [p1.master, p3.master]) }
  let(:ocB) { create(:simple_order_cycle, coordinator: c2, distributors: [d1, d2], suppliers: [s1, s2, s3], variants: [p2.master]) }

  # orderA1 can only be accessed by s1, s3 and d1
  let(:orderA1) do
    order = create(:order, distributor: d1, bill_address: ba, ship_address: sa, special_instructions: si, order_cycle: ocA)
    order.line_items << create(:line_item, variant: p1.master)
    order.line_items << create(:line_item, variant: p3.master)
    order.finalize!
    order.save
    order
  end
  # orderA2 can only be accessed by s2 and d2
  let(:orderA2) do
    order = create(:order, distributor: d2, bill_address: ba, ship_address: sa, special_instructions: si, order_cycle: ocA)
    order.line_items << create(:line_item, variant: p2.master)
    order.finalize!
    order.save
    order
  end
  # orderB1 can only be accessed by s1, s3 and d1
  let(:orderB1) do
    order = create(:order, distributor: d1, bill_address: ba, ship_address: sa, special_instructions: si, order_cycle: ocB)
    order.line_items << create(:line_item, variant: p1.master)
    order.line_items << create(:line_item, variant: p3.master)
    order.finalize!
    order.save
    order
  end
  # orderB2 can only be accessed by s2 and d2
  let(:orderB2) do
    order = create(:order, distributor: d2, bill_address: ba, ship_address: sa, special_instructions: si, order_cycle: ocB)
    order.line_items << create(:line_item, variant: p2.master)
    order.finalize!
    order.save
    order
  end

  # Results
  let(:resulting_orders_prelim) { assigns(:report).search.result }
  let(:resulting_orders) { assigns(:report).table_items.map(&:order) }
  let(:resulting_products) { assigns(:report).table_items.map(&:product) }

  # As manager of a coordinator (c1)
  context "Coordinator Enterprise User" do
    before { login_as_enterprise_user [c1] }

    describe 'Orders & Fulfillment' do
      it "shows all orders in order cycles I coordinate" do
        # create test objects
        [orderA1, orderA2, orderB1, orderB2]

        spree_get :orders_and_fulfillment

        expect(resulting_orders).to     include orderA1, orderA2
        expect(resulting_orders).not_to include orderB1, orderB2
      end
    end
  end

  # As a Distributor Enterprise user for d1
  context "Distributor Enterprise User" do
    before { login_as_enterprise_user [d1] }

    describe 'Orders and Distributors' do
      it "only shows orders that I have access to" do
        [orderA1, orderA2, orderB1, orderB2]
        spree_get :orders_and_distributors

        expect(assigns(:search).result).to include(orderA1, orderB1)
        expect(assigns(:search).result).not_to include(orderA2)
        expect(assigns(:search).result).not_to include(orderB2)
      end
    end

    describe 'Bulk Coop' do
      it "only shows orders that I have access to" do
        [orderA1, orderA2, orderB1, orderB2]
        spree_get :bulk_coop

        expect(resulting_orders).to     include(orderA1, orderB1)
        expect(resulting_orders).not_to include(orderA2)
        expect(resulting_orders).not_to include(orderB2)
      end
    end

    describe 'Payments' do
      it "only shows orders that I have access to" do
        [orderA1, orderA2, orderB1, orderB2]
        spree_get :payments

        expect(resulting_orders_prelim).to     include(orderA1, orderB1)
        expect(resulting_orders_prelim).not_to include(orderA2)
        expect(resulting_orders_prelim).not_to include(orderB2)
      end
    end

    describe 'Orders & Fulfillment' do
      it "only shows orders that I distribute" do
        [orderA1, orderA2, orderB1, orderB2]
        spree_get :orders_and_fulfillment

        expect(resulting_orders).to     include orderA1, orderB1
        expect(resulting_orders).not_to include orderA2, orderB2
      end

      it "only shows the selected order cycle" do
        [orderA1, orderB1]
        spree_get :orders_and_fulfillment, q: {order_cycle_id_in: [ocA.id.to_s]}

        expect(resulting_orders).to     include(orderA1)
        expect(resulting_orders).not_to include(orderB1)
      end
    end
  end

  # As a Supplier Enterprise user for s1
  context "Supplier" do
    before { login_as_enterprise_user [s1] }

    describe 'index' do
      it "loads reports relevant to producers" do
        spree_get :index

        report_types = assigns(:reports).keys
        expect(report_types).to include "orders_and_fulfillment", "products_and_inventory", "packing" # and others
        expect(report_types).to_not include "sales_tax"
      end
    end

    describe 'Bulk Coop' do
      context "where I have granted P-OC to the distributor" do
        before do
          [orderA1, orderA2]
          create(:enterprise_relationship, parent: s1, child: d1, permissions_list: [:add_to_order_cycle])
        end

        it "only shows product line items that I am supplying" do
          spree_get :bulk_coop

          expect(resulting_products).to     include p1
          expect(resulting_products).not_to include p2, p3
        end
      end

      context "where I have not granted P-OC to the distributor" do
        it "shows product line items that I am supplying" do
          spree_get :bulk_coop

          expect(resulting_products).not_to include p1, p2, p3
        end
      end
    end

    describe 'Orders & Fulfillment' do
      context "where I have granted P-OC to the distributor" do
        before do
          create(:enterprise_relationship, parent: s1, child: d1, permissions_list: [:add_to_order_cycle])
        end

        it "only shows product line items that I am supplying" do
          [orderA1, orderA2]
          spree_get :orders_and_fulfillment

          expect(resulting_products).to     include p1
          expect(resulting_products).not_to include p2, p3
        end

        it "only shows the selected order cycle" do
          [orderA1, orderB1]
          spree_get :orders_and_fulfillment, q: {order_cycle_id_eq: ocA.id}

          expect(resulting_orders_prelim).to     include(orderA1)
          expect(resulting_orders_prelim).not_to include(orderB1)
        end
      end

      context "where I have not granted P-OC to the distributor" do
        it "does not show me line_items I supply" do
          [orderA1, orderA2]
          spree_get :orders_and_fulfillment

          expect(resulting_products).not_to include p1, p2, p3
        end
      end
    end
  end

  context "Products & Inventory" do
    before { login_as_admin }

    it "should build distributors for the current user" do
      [c1, c2, s1, d1, d2, d3]
      spree_get :products_and_inventory
      expect(assigns(:distributors)).to match_array [c1, c2, d1, d2, d3]
    end

    it "builds suppliers for the current user" do
      [s1, s2, s3, d1]
      spree_get :products_and_inventory
      expect(assigns(:suppliers)).to match_array [s1, s2, s3]
    end

    it "builds order cycles for the current user" do
      [ocA, ocB]
      spree_get :products_and_inventory
      expect(assigns(:order_cycles)).to match_array [ocB, ocA]
    end

    it "assigns report types" do
      spree_get :products_and_inventory
      expect(assigns(:report_types)).to eq(subject.report_types[:products_and_inventory])
    end

    it "creates a ProductAndInventoryReport" do
      expect(OpenFoodNetwork::ProductsAndInventoryReport).to receive(:new)
        .with(@admin_user, {"test" => "foo", "controller" => "spree/admin/reports", "action" => "products_and_inventory"})
        .and_return(report = double(:report))
      allow(report).to receive(:header).and_return []
      allow(report).to receive(:table).and_return []
      spree_get :products_and_inventory, test: "foo"
      expect(assigns(:report)).to eq(report)
    end
  end

  context "My Customers" do
    before { login_as_admin }

    it "should have report types for customers" do
      expect(subject.report_types[:customers]).to eq([
        ["Mailing List", :mailing_list],
        ["Addresses", :addresses]
      ])
    end

    it "should build distributors for the current user" do
      [c1, c2, s1, d1, d2, d3]
      spree_get :customers
      expect(assigns(:distributors)).to match_array [c1, c2, d1, d2, d3]
    end

    it "builds suppliers for the current user" do
      [s1, s2, s3, d1]
      spree_get :customers
      expect(assigns(:suppliers)).to match_array [s1, s2, s3]
    end

    it "builds order cycles for the current user" do
      [ocA, ocB]
      spree_get :customers
      expect(assigns(:order_cycles)).to match_array [ocB, ocA]
    end

    it "assigns report types" do
      spree_get :customers
      expect(assigns(:report_types)).to eq(subject.report_types[:customers])
    end

    it "creates a CustomersReport" do
      expect(OpenFoodNetwork::CustomersReport).to receive(:new)
        .with(@admin_user, {"test" => "foo", "controller" => "spree/admin/reports", "action" => "customers"}, false)
        .and_return(report = double(:report))
      allow(report).to receive(:header).and_return []
      allow(report).to receive(:table).and_return []
      spree_get :customers, test: "foo"
      expect(assigns(:report)).to eq(report)
    end
  end

  context "Admin" do
    before { login_as_admin }

    describe "users_and_enterprises" do
      it "shows report search forms" do
        spree_get :users_and_enterprises
        expect(assigns(:report).table).to eq []
      end

      it "shows report data" do
      	[c1]
        spree_post :users_and_enterprises
        expect(assigns(:report).table.empty?).to be false
      end
    end
  end
end
