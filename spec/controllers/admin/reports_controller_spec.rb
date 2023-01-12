# frozen_string_literal: true

require 'spec_helper'

describe Admin::ReportsController, type: :controller do
  # Given two distributors and two suppliers
  let(:bill_address) { create(:address) }
  let(:ship_address) { create(:address) }
  let(:instructions) { "pick up on thursday please" }
  let(:coordinator1) { create(:distributor_enterprise) }
  let(:coordinator2) { create(:distributor_enterprise) }
  let(:supplier1) { create(:supplier_enterprise) }
  let(:supplier2) { create(:supplier_enterprise) }
  let(:supplier3) { create(:supplier_enterprise) }
  let(:distributor1) { create(:distributor_enterprise) }
  let(:distributor2) { create(:distributor_enterprise) }
  let(:distributor3) { create(:distributor_enterprise) }
  let(:product1) { create(:product, price: 12.34, supplier: supplier1) }
  let(:product2) { create(:product, price: 23.45, supplier: supplier2) }
  let(:product3) { create(:product, price: 34.56, supplier: supplier3) }

  # Given two order cycles with both distributors
  let(:ocA) {
    create(:simple_order_cycle, coordinator: coordinator1,
                                distributors: [distributor1, distributor2],
                                suppliers: [supplier1, supplier2, supplier3],
                                variants: [product1.master, product3.master])
  }
  let(:ocB) {
    create(:simple_order_cycle, coordinator: coordinator2,
                                distributors: [distributor1, distributor2],
                                suppliers: [supplier1, supplier2, supplier3],
                                variants: [product2.master])
  }

  # orderA1 can only be accessed by supplier1, supplier3 and distributor1
  let(:orderA1) do
    order = create(:order, distributor: distributor1, bill_address: bill_address,
                           ship_address: ship_address, special_instructions: instructions,
                           order_cycle: ocA)
    order.line_items << create(:line_item, variant: product1.master)
    order.line_items << create(:line_item, variant: product3.master)
    order.finalize!
    order.save
    order
  end
  # orderA2 can only be accessed by supplier2 and distributor2
  let(:orderA2) do
    order = create(:order, distributor: distributor2, bill_address: bill_address,
                           ship_address: ship_address, special_instructions: instructions,
                           order_cycle: ocA)
    order.line_items << create(:line_item, variant: product2.master)
    order.finalize!
    order.save
    order
  end
  # orderB1 can only be accessed by supplier1, supplier3 and distributor1
  let(:orderB1) do
    order = create(:order, distributor: distributor1, bill_address: bill_address,
                           ship_address: ship_address, special_instructions: instructions,
                           order_cycle: ocB)
    order.line_items << create(:line_item, variant: product1.master)
    order.line_items << create(:line_item, variant: product3.master)
    order.finalize!
    order.save
    order
  end
  # orderB2 can only be accessed by supplier2 and distributor2
  let(:orderB2) do
    order = create(:order, distributor: distributor2, bill_address: bill_address,
                           ship_address: ship_address, special_instructions: instructions,
                           order_cycle: ocB)
    order.line_items << create(:line_item, variant: product2.master)
    order.finalize!
    order.save
    order
  end

  # Results
  let(:resulting_orders_prelim) { assigns(:report).search.result }
  let(:resulting_line_items) { assigns(:report).query_result.flatten }
  let(:resulting_orders) { resulting_line_items.map(&:order).uniq }
  let(:resulting_products) { resulting_line_items.map(&:product).uniq }

  # As manager of a coordinator (coordinator1)
  context "Coordinator Enterprise User" do
    let!(:present_objects) { [orderA1, orderA2, orderB1, orderB2] }

    before { controller_login_as_enterprise_user [coordinator1] }

    describe 'Orders & Fulfillment' do
      it "shows all orders in order cycles I coordinate" do
        spree_post :show, report_type: :orders_and_fulfillment, q: {}
        expect(resulting_orders).to     include orderA1, orderA2
        expect(resulting_orders).not_to include orderB1, orderB2
      end
    end
  end

  # As a Distributor Enterprise user for distributor1
  context "Distributor Enterprise User" do
    before { controller_login_as_enterprise_user [distributor1] }

    describe 'Orders and Distributors' do
      let!(:present_objects) { [orderA1, orderA2, orderB1, orderB2] }

      it "only shows orders that I have access to" do
        spree_post :show, report_type: :orders_and_distributors

        expect(assigns(:report).search.result).to include(orderA1, orderB1)
        expect(assigns(:report).search.result).not_to include(orderA2)
        expect(assigns(:report).search.result).not_to include(orderB2)
      end
    end

    describe 'Payments' do
      let!(:present_objects) { [orderA1, orderA2, orderB1, orderB2] }

      it "only shows orders that I have access to" do
        spree_post :show, report_type: :payments

        expect(resulting_orders_prelim).to     include(orderA1, orderB1)
        expect(resulting_orders_prelim).not_to include(orderA2)
        expect(resulting_orders_prelim).not_to include(orderB2)
      end
    end

    describe 'Orders & Fulfillment' do
      context "with four orders" do
        let!(:present_objects) { [orderA1, orderA2, orderB1, orderB2] }

        it "only shows orders that I distribute" do
          spree_post :show, report_type: :orders_and_fulfillment, q: {}

          expect(resulting_orders).to     include orderA1, orderB1
          expect(resulting_orders).not_to include orderA2, orderB2
        end
      end

      context "with two orders" do
        let!(:present_objects) { [orderA1, orderB1] }

        it "only shows the selected order cycle" do
          spree_post :show, report_type: :orders_and_fulfillment,
                            q: { order_cycle_id_in: [ocA.id.to_s] }

          expect(resulting_orders).to     include(orderA1)
          expect(resulting_orders).not_to include(orderB1)
        end
      end
    end
  end

  # As a Supplier Enterprise user for supplier1
  context "Supplier" do
    before { controller_login_as_enterprise_user [supplier1] }

    describe 'index' do
      it "loads reports relevant to producers" do
        spree_get :index

        report_types = assigns(:reports).keys
        expect(report_types).to include :orders_and_fulfillment,
                                        :products_and_inventory, :packing # and others
        expect(report_types).to_not include :sales_tax
      end
    end

    describe 'Orders & Fulfillment' do
      let!(:present_objects) { [orderA1, orderA2] }

      context "where I have granted P-OC to the distributor" do
        before do
          create(:enterprise_relationship, parent: supplier1, child: distributor1,
                                           permissions_list: [:add_to_order_cycle])
        end

        it "only shows product line items that I am supplying" do
          spree_post :show, report_type: :orders_and_fulfillment, q: {}

          expect(resulting_products).to     include product1
          expect(resulting_products).not_to include product2, product3
        end

        it "only shows the selected order cycle" do
          spree_post :show, report_type: :orders_and_fulfillment, q: { order_cycle_id_eq: ocA.id }

          expect(resulting_orders_prelim).to     include(orderA1)
          expect(resulting_orders_prelim).not_to include(orderB1)
        end

        context 'when a purchased product is deleted' do
          before { orderA1.line_items.first.product.destroy }

          it "only shows product line items that I am supplying" do
            spree_post :show, report_type: :orders_and_fulfillment, q: {}

            variant = Spree::Variant.unscoped.find(resulting_line_items.first.variant_id)

            expect(variant.product).to eq(product1)
          end
        end
      end

      context "where I have not granted P-OC to the distributor" do
        it "does not show me line_items I supply" do
          spree_post :show, report_type: :orders_and_fulfillment

          expect(resulting_products).not_to include product1, product2, product3
        end
      end
    end
  end

  context "Products & Inventory" do
    before { controller_login_as_admin }

    context "with distributors and suppliers" do
      let(:distributors) { [coordinator1, distributor1, distributor2] }
      let(:suppliers) { [supplier1, supplier2] }
      let!(:present_objects) { [distributors, suppliers] }

      it "should build distributors for the current user" do
        spree_get :show, report_type: :products_and_inventory
        expect(assigns(:data).distributors).to match_array distributors
      end

      it "builds suppliers for the current user" do
        spree_get :show, report_type: :products_and_inventory
        expect(assigns(:data).suppliers).to match_array suppliers
      end
    end

    context "with order cycles" do
      let!(:order_cycles) { [ocA, ocB] }

      it "builds order cycles for the current user" do
        spree_get :show, report_type: :products_and_inventory
        expect(assigns(:data).order_cycles).to match_array order_cycles
      end
    end

    it "assigns report types" do
      spree_get :show, report_type: :products_and_inventory
      expect(assigns(:report_subtypes)).to eq(subject.reports[:products_and_inventory])
    end

    it "creates a ProductAndInventoryReport" do
      allow(Reporting::Reports::ProductsAndInventory::Base).to receive(:new)
        .and_return(report = double(:report))
      allow(report).to receive(:table_headers).and_return []
      allow(report).to receive(:table_rows).and_return []
      allow(report).to receive(:columns).and_return({})
      allow(report).to receive(:fields_to_hide).and_return([])
      spree_get :show, report_type: :products_and_inventory, test: "foo"
      expect(assigns(:report)).to eq(report)
    end
  end

  context "My Customers" do
    before { controller_login_as_admin }

    it "should have report types for customers" do
      expect(subject.reports[:customers]).to eq([
                                                  ["Mailing List", :mailing_list],
                                                  ["Addresses", :addresses]
                                                ])
    end

    context "with distributors and suppliers" do
      let(:distributors) { [coordinator1, distributor1, distributor2] }
      let(:suppliers) { [supplier1, supplier2] }
      let!(:present_objects) { [distributors, suppliers] }

      it "should build distributors for the current user" do
        spree_get :show, report_type: :customers
        expect(assigns(:data).distributors).to match_array distributors
      end

      it "builds suppliers for the current user" do
        spree_get :show, report_type: :customers
        expect(assigns(:data).suppliers).to match_array suppliers
      end
    end

    context "with order cycles" do
      let!(:order_cycles) { [ocA, ocB] }

      it "builds order cycles for the current user" do
        spree_get :show, report_type: :customers
        expect(assigns(:data).order_cycles).to match_array order_cycles
      end
    end

    it "assigns report types" do
      spree_get :show, report_type: :customers
      expect(assigns(:report_subtypes)).to eq(subject.reports[:customers])
    end

    it "creates a report object" do
      allow(Reporting::Reports::Customers::Base).to receive(:new)
        .and_return(report = double(:report))
      allow(report).to receive(:table_headers).and_return []
      allow(report).to receive(:table_rows).and_return []
      allow(report).to receive(:columns).and_return({})
      allow(report).to receive(:fields_to_hide).and_return([])
      spree_get :show, report_type: :customers, test: "foo"
      expect(assigns(:report)).to eq(report)
    end
  end

  context 'Order Cycle Management' do
    let!(:present_objects) { [orderA1, orderA2, orderB1, orderB2] }

    before do
      controller_login_as_enterprise_user [coordinator1]
    end

    it 'renders the delivery report' do
      spree_post :show, {
        q: { completed_at_lt: 1.day.ago },
        shipping_method_in: ["123"], # We just need to search for shipping methods
        report_type: :order_cycle_management,
        report_subtype: "delivery",
      }

      expect(response).to have_http_status(:ok)
    end
  end

  context "Admin" do
    before { controller_login_as_admin }

    describe "users_and_enterprises" do
      let!(:present_objects) { [coordinator1] }

      it "shows report search forms" do
        spree_get :show, report_type: :users_and_enterprises
        expect(response).to have_http_status(:ok)
      end

      it "shows report data" do
        spree_post :show, report_type: :users_and_enterprises, q: {}
        expect(assigns(:report).table_rows.empty?).to be false
      end
    end

    describe "sales_tax" do
      it "shows report search forms" do
        spree_get :show, report_type: :sales_tax
        expect(response).to have_http_status(:ok)
      end
    end
  end

  context "Sales Tax Reports By Order" do
    let!(:present_objects) { [orderA1, orderA2, orderB1, orderB2] }
    let(:report_type) { :sales_tax_totals_by_order }
    context "as an admin" do
      before do
        controller_login_as_admin
      end
      it "generates the report" do
        spree_get :show, report_type: :sales_tax, report_subtype: report_type
        expect(response).to have_http_status(:ok)
        expect(resulting_orders_prelim).to include(orderA1, orderA2, orderB1, orderB2)
      end
    end
    context "as distributor1" do
      before { controller_login_as_enterprise_user [distributor1] }
      it "generates the report" do
        spree_get :show, report_type: :sales_tax, report_subtype: report_type
        expect(response).to have_http_status(:ok)
        expect(resulting_orders_prelim).to include(orderA1, orderB1)
        expect(resulting_orders_prelim).to_not include(orderA2, orderB2)
      end
    end
  end
end
