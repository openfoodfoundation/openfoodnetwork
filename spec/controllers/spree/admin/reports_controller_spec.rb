require 'spec_helper'

describe Spree::Admin::ReportsController do

  # Given two distributors and two suppliers
  let(:ba) { create(:address) }
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
    order = create(:order, distributor: d1, bill_address: ba, special_instructions: si, order_cycle: ocA)
    order.line_items << create(:line_item, variant: p1.master)
    order.line_items << create(:line_item, variant: p3.master)
    order.finalize!
    order.save
    order
  end
  # orderA2 can only be accessed by s2 and d2
  let!(:orderA2) do
    order = create(:order, distributor: d2, bill_address: ba, special_instructions: si, order_cycle: ocA)
    order.line_items << create(:line_item, variant: p2.master)
    order.finalize!
    order.save
    order
  end
  # orderB1 can only be accessed by s1, s3 and d1
  let!(:orderB1) do
    order = create(:order, distributor: d1, bill_address: ba, special_instructions: si, order_cycle: ocB)
    order.line_items << create(:line_item, variant: p1.master)
    order.line_items << create(:line_item, variant: p3.master)
    order.finalize!
    order.save
    order
  end
  # orderB2 can only be accessed by s2 and d2
  let!(:orderB2) do
    order = create(:order, distributor: d2, bill_address: ba, special_instructions: si, order_cycle: ocB)
    order.line_items << create(:line_item, variant: p2.master)
    order.finalize!
    order.save
    order
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
      assigns(:report_types).should == Spree::Admin::ReportsController::REPORT_TYPES[:products_and_inventory]
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
      Spree::Admin::ReportsController::REPORT_TYPES[:customers].should == [
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
      assigns(:report_types).should == Spree::Admin::ReportsController::REPORT_TYPES[:customers]
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
