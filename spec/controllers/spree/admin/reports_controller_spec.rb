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
  let!(:orderA1) do
    order = create(:order, distributor: d1, bill_address: ba, ship_address: sa, special_instructions: si, order_cycle: ocA)
    order.line_items << create(:line_item, variant: p1.master)
    order.line_items << create(:line_item, variant: p3.master)
    order.finalize!
    order.save
    order
  end
  # orderA2 can only be accessed by s2 and d2
  let!(:orderA2) do
    order = create(:order, distributor: d2, bill_address: ba, ship_address: sa, special_instructions: si, order_cycle: ocA)
    order.line_items << create(:line_item, variant: p2.master)
    order.finalize!
    order.save
    order
  end
  # orderB1 can only be accessed by s1, s3 and d1
  let!(:orderB1) do
    order = create(:order, distributor: d1, bill_address: ba, ship_address: sa, special_instructions: si, order_cycle: ocB)
    order.line_items << create(:line_item, variant: p1.master)
    order.line_items << create(:line_item, variant: p3.master)
    order.finalize!
    order.save
    order
  end
  # orderB2 can only be accessed by s2 and d2
  let!(:orderB2) do
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
        spree_get :orders_and_fulfillment

        resulting_orders.should     include orderA1, orderA2
        resulting_orders.should_not include orderB1, orderB2
      end
    end
  end

  # As a Distributor Enterprise user for d1
  context "Distributor Enterprise User" do
    before { login_as_enterprise_user [d1] }

    describe 'Orders and Distributors' do
      it "only shows orders that I have access to" do
        spree_get :orders_and_distributors

        assigns(:search).result.should include(orderA1, orderB1)
        assigns(:search).result.should_not include(orderA2)
        assigns(:search).result.should_not include(orderB2)
      end
    end

    describe 'Bulk Coop' do
      it "only shows orders that I have access to" do
        spree_get :bulk_coop

        resulting_orders.should     include(orderA1, orderB1)
        resulting_orders.should_not include(orderA2)
        resulting_orders.should_not include(orderB2)
      end
    end

    describe 'Payments' do
      it "only shows orders that I have access to" do
        spree_get :payments

        resulting_orders_prelim.should     include(orderA1, orderB1)
        resulting_orders_prelim.should_not include(orderA2)
        resulting_orders_prelim.should_not include(orderB2)
      end
    end

    describe 'Orders & Fulfillment' do
      it "only shows orders that I distribute" do
        spree_get :orders_and_fulfillment

        resulting_orders.should     include orderA1, orderB1
        resulting_orders.should_not include orderA2, orderB2
      end

      it "only shows the selected order cycle" do
        spree_get :orders_and_fulfillment, q: {order_cycle_id_in: [ocA.id.to_s]}

        resulting_orders.should     include(orderA1)
        resulting_orders.should_not include(orderB1)
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
          create(:enterprise_relationship, parent: s1, child: d1, permissions_list: [:add_to_order_cycle])
        end

        it "only shows product line items that I am supplying" do
          spree_get :bulk_coop

          resulting_products.should     include p1
          resulting_products.should_not include p2, p3
        end
      end

      context "where I have not granted P-OC to the distributor" do
        it "shows product line items that I am supplying" do
          spree_get :bulk_coop

          resulting_products.should_not include p1, p2, p3
        end
      end
    end

    describe 'Orders & Fulfillment' do
      context "where I have granted P-OC to the distributor" do
        before do
          create(:enterprise_relationship, parent: s1, child: d1, permissions_list: [:add_to_order_cycle])
        end

        it "only shows product line items that I am supplying" do
          spree_get :orders_and_fulfillment

          resulting_products.should     include p1
          resulting_products.should_not include p2, p3
        end

        it "only shows the selected order cycle" do
          spree_get :orders_and_fulfillment, q: {order_cycle_id_eq: ocA.id}

          resulting_orders_prelim.should     include(orderA1)
          resulting_orders_prelim.should_not include(orderB1)
        end
      end

      context "where I have not granted P-OC to the distributor" do
        it "does not show me line_items I supply" do
          spree_get :orders_and_fulfillment

          resulting_products.should_not include p1, p2, p3
        end
      end
    end
  end

  context "Products & Inventory" do
    before { login_as_admin }

    it "should build distributors for the current user" do
      spree_get :products_and_inventory
      assigns(:distributors).should match_array [c1, c2, d1, d2, d3]
    end

    it "builds suppliers for the current user" do
      spree_get :products_and_inventory
      assigns(:suppliers).should match_array [s1, s2, s3]
    end

    it "builds order cycles for the current user" do
      spree_get :products_and_inventory
      assigns(:order_cycles).should match_array [ocB, ocA]
    end

    it "assigns report types" do
      spree_get :products_and_inventory
      assigns(:report_types).should == subject.report_types[:products_and_inventory]
    end

    it "creates a ProductAndInventoryReport" do
      OpenFoodNetwork::ProductsAndInventoryReport.should_receive(:new)
        .with(@admin_user, {"test" => "foo", "controller" => "spree/admin/reports", "action" => "products_and_inventory"})
        .and_return(report = double(:report))
      report.stub(:header).and_return []
      report.stub(:table).and_return []
      spree_get :products_and_inventory, test: "foo"
      assigns(:report).should == report
    end
  end

  context "My Customers" do
    before { login_as_admin }

    it "should have report types for customers" do
      subject.report_types[:customers].should == [
        ["Mailing List", :mailing_list],
        ["Addresses", :addresses]
      ]
    end

    it "should build distributors for the current user" do
      spree_get :customers
      assigns(:distributors).should match_array [c1, c2, d1, d2, d3]
    end

    it "builds suppliers for the current user" do
      spree_get :customers
      assigns(:suppliers).should match_array [s1, s2, s3]
    end

    it "builds order cycles for the current user" do
      spree_get :customers
      assigns(:order_cycles).should match_array [ocB, ocA]
    end

    it "assigns report types" do
      spree_get :customers
      assigns(:report_types).should == subject.report_types[:customers]
    end

    it "creates a CustomersReport" do
      OpenFoodNetwork::CustomersReport.should_receive(:new)
        .with(@admin_user, {"test" => "foo", "controller" => "spree/admin/reports", "action" => "customers"})
        .and_return(report = double(:report))
      report.stub(:header).and_return []
      report.stub(:table).and_return []
      spree_get :customers, test: "foo"
      assigns(:report).should == report
    end
  end
end
