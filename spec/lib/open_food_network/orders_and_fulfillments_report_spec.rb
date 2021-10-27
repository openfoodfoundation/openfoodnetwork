# frozen_string_literal: true

require 'spec_helper'
require 'open_food_network/orders_and_fulfillments_report'
require 'open_food_network/order_grouper'

describe OpenFoodNetwork::OrdersAndFulfillmentsReport do
  include AuthenticationHelper

  let(:distributor) { create(:distributor_enterprise) }
  let(:order_cycle) { create(:simple_order_cycle) }
  let(:address) { create(:address) }
  let(:order) {
    create(
      :order,
      completed_at: 1.day.ago,
      order_cycle: order_cycle,
      distributor: distributor,
      bill_address: address
    )
  }
  let(:line_item) { build(:line_item_with_shipment) }
  let(:user) { create(:user) }
  let(:admin_user) { create(:admin_user) }

  describe "fetching orders" do
    before { order.line_items << line_item }

    context "as a site admin" do
      subject { described_class.new(admin_user, {}, true) }

      it "fetches completed orders" do
        o2 = create(:order)
        o2.line_items << build(:line_item)
        expect(subject.table_items).to eq([line_item])
      end

      it "does not show cancelled orders" do
        o2 = create(:order, state: "canceled", completed_at: 1.day.ago)
        o2.line_items << build(:line_item_with_shipment)
        expect(subject.table_items).to eq([line_item])
      end
    end

    context "as a manager of a supplier" do
      subject { described_class.new(user, {}, true) }

      let(:s1) { create(:supplier_enterprise) }

      before do
        s1.enterprise_roles.create!(user: user)
      end

      context "that has granted P-OC to the distributor" do
        let(:o2) {
          create(
            :order,
            distributor: distributor,
            completed_at: 1.day.ago,
            bill_address: create(:address),
            ship_address: create(:address)
          )
        }
        let(:li2) {
          build(:line_item_with_shipment, product: create(:simple_product, supplier: s1))
        }

        before do
          o2.line_items << li2
          create(
            :enterprise_relationship,
            parent: s1,
            child: distributor,
            permissions_list: [:add_to_order_cycle]
          )
        end

        it "shows line items supplied by my producers, with names hidden" do
          expect(subject.table_items).to eq([li2])
          expect(subject.table_items.first.order.bill_address.firstname).to eq("HIDDEN")
        end

        context "where the distributor allows suppliers to see customer names" do
          before do
            distributor.update_columns show_customer_names_to_suppliers: true
          end

          it "shows line items supplied by my producers, with names shown" do
            expect(subject.table_items).to eq([li2])
            expect(subject.table_items.first.order.bill_address.firstname).
              to eq(order.bill_address.firstname)
          end
        end
      end

      context "that has not granted P-OC to the distributor" do
        let(:o2) {
          create(
            :order,
            distributor: distributor,
            completed_at: 1.day.ago,
            bill_address: create(:address),
            ship_address: create(:address)
          )
        }
        let(:li2) {
          build(:line_item_with_shipment, product: create(:simple_product, supplier: s1))
        }

        before do
          o2.line_items << li2
        end

        it "does not show line items supplied by my producers" do
          expect(subject.table_items).to eq([])
        end

        context "where the distributor allows suppliers to see customer names" do
          before do
            distributor.show_customer_names_to_suppliers = true
          end

          it "does not show line items supplied by my producers" do
            expect(subject.table_items).to eq([])
          end
        end
      end
    end

    context "as a manager of a distributor" do
      subject { described_class.new(user, {}, true) }

      before do
        distributor.enterprise_roles.create!(user: user)
      end

      it "only shows line items distributed by enterprises managed by the current user" do
        d2 = create(:distributor_enterprise)
        d2.enterprise_roles.create!(user: create(:user))
        o2 = create(:order, distributor: d2, completed_at: 1.day.ago)
        o2.line_items << build(:line_item_with_shipment)
        expect(subject.table_items).to eq([line_item])
      end

      it "only shows the selected order cycle" do
        oc2 = create(:simple_order_cycle)
        o2 = create(:order, distributor: distributor, order_cycle: oc2)
        o2.line_items << build(:line_item)
        allow(subject).to receive(:params).and_return(order_cycle_id_in: order_cycle.id)
        expect(subject.table_items).to eq([line_item])
      end
    end
  end

  describe "columns are aligned" do
    it 'has aligned columsn' do
      report_types = [
        "",
        "order_cycle_supplier_totals",
        "order_cycle_supplier_totals_by_distributor",
        "order_cycle_distributor_totals_by_supplier",
        "order_cycle_customer_totals"
      ]

      report_types.each do |report_type|
        report = described_class.new(admin_user, report_type: report_type)
        expect(report.header.size).to eq(report.columns.size)
      end
    end
  end

  describe "order_cycle_customer_totals" do
    let!(:product) { line_item.product }
    let!(:fuji) do
      create(:variant, product: product, display_name: "Fuji", sku: "FUJI", on_hand: 100)
    end
    let!(:gala) do
      create(:variant, product: product, display_name: "Gala", sku: "GALA", on_hand: 100)
    end

    let(:items) {
      report = described_class.new(admin_user, { report_type: "order_cycle_customer_totals" }, true)
      OpenFoodNetwork::OrderGrouper.new(report.rules, report.columns).table(report.table_items)
    }

    before do
      # Clear price so it will be computed based on quantity and variant price.
      order.line_items << build(:line_item_with_shipment, variant: fuji, price: nil, quantity: 1)
      order.line_items << build(:line_item_with_shipment, variant: gala, price: nil, quantity: 2)
    end

    it "has a product row" do
      product_name_field = items.first[5]
      expect(product_name_field).to eq product.name
    end

    it "has a summary row" do
      product_name_field = items.last[5]
      expect(product_name_field).to eq "TOTAL"
    end

    # Expected Report for Scenario:
    #
    # Row 1: Armstrong Amari, Fuji Apple, price: 8
    # Row 2: SUMMARY
    # Row 3: Bartoletti Brooklyn, Fuji Apple, price: 1 + 4
    # Row 4: Bartoletti Brooklyn, Gala Apple, price: 2
    # Row 5: SUMMARY
    describe "grouping of line items" do
      let!(:address) { create(:address, last_name: "Bartoletti", first_name: "Brooklyn") }

      let!(:second_address) { create(:address, last_name: "Armstrong", first_name: "Amari") }
      let!(:second_order) do
        create(:order, completed_at: 1.day.ago, order_cycle: order_cycle, distributor: distributor,
                       bill_address: second_address)
      end

      before do
        # Add a second line item for Fuji variant to the order, to test grouping in this edge case.
        order.line_items << build(:line_item_with_shipment, variant: fuji, price: nil, quantity: 4)

        second_order.line_items << build(:line_item_with_shipment, variant: fuji, price: nil,
                                                                   quantity: 8)
      end

      it "groups line items by variant and order" do
        expect(items.length).to eq(5)

        # Row 1: Armstrong Amari, Fuji Apple, price: 8
        row_data = items[0]
        expect(customer_name(row_data)).to eq(second_address.full_name)
        expect(amount(row_data)).to eq(fuji.price * 8)
        expect(variant_sku(row_data)).to eq(fuji.sku)

        # Row 2: SUMMARY
        row_data = items[1]
        expect(totals_row?(row_data)).to eq(true)
        expect(customer_name(row_data)).to eq(second_address.full_name)
        expect(amount(row_data)).to eq(fuji.price * 8)

        # Row 3: Bartoletti Brooklyn, Fuji Apple, price: 1 + 4
        row_data = items[2]
        expect(customer_name(row_data)).to eq(address.full_name)
        expect(amount(row_data)).to eq(fuji.price * 5)
        expect(variant_sku(row_data)).to eq(fuji.sku)

        # Row 4: Bartoletti Brooklyn, Gala Apple, price: 2
        row_data = items[3]
        expect(customer_name(row_data)).to eq(address.full_name)
        expect(amount(row_data)).to eq(gala.price * 2)
        expect(variant_sku(row_data)).to eq(gala.sku)

        # Row 5: SUMMARY
        row_data = items[4]
        expect(totals_row?(row_data)).to eq(true)
        expect(customer_name(row_data)).to eq(address.full_name)
        expect(amount(row_data)).to eq(fuji.price * 5 + gala.price * 2)
      end
    end

    def totals_row?(row_data)
      row_data[5] == I18n.t("admin.reports.total")
    end

    def customer_name(row_data)
      row_data[1]
    end

    def amount(row_data)
      row_data[8]
    end

    def variant_sku(row_data)
      row_data[23]
    end
  end
end
