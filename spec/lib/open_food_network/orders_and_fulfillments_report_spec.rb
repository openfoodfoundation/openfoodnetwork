require 'spec_helper'

describe OpenFoodNetwork::OrdersAndFulfillmentsReport do
  include AuthenticationWorkflow

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
  let(:line_item) { build(:line_item) }
  let(:user) { create(:user) }
  let(:admin_user) { create(:admin_user) }

  before { order.line_items << line_item }

  describe "fetching orders" do
    context "as a site admin" do
      subject { described_class.new admin_user, {}, true }

      it "fetches completed orders" do
        o2 = create(:order)
        o2.line_items << build(:line_item)
        expect(subject.table_items).to eq([line_item])
      end

      it "does not show cancelled orders" do
        o2 = create(:order, state: "canceled", completed_at: 1.day.ago)
        o2.line_items << build(:line_item)
        expect(subject.table_items).to eq([line_item])
      end
    end

    context "as a manager of a supplier" do
      subject { described_class.new user, {}, true }

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
        let(:li2) { build(:line_item, product: create(:simple_product, supplier: s1)) }

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
        let(:li2) { build(:line_item, product: create(:simple_product, supplier: s1)) }

        before do
          o2.line_items << li2
        end

        it "shows line items supplied by my producers, with names hidden" do
          expect(subject.table_items).to eq([])
        end
      end
    end

    context "as a manager of a distributor" do
      subject { described_class.new user, {}, true }

      before do
        distributor.enterprise_roles.create!(user: user)
      end

      it "only shows line items distributed by enterprises managed by the current user" do
        d2 = create(:distributor_enterprise)
        d2.enterprise_roles.create!(user: create(:user))
        o2 = create(:order, distributor: d2, completed_at: 1.day.ago)
        o2.line_items << build(:line_item)
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
        report = described_class.new admin_user, report_type: report_type
        expect(report.header.size).to eq(report.columns.size)
      end
    end
  end

  describe "order_cycle_customer_totals" do
    let(:product) { line_item.product }
    let(:fuji) { product.variants.first }
    let(:items) {
      report = described_class.new(admin_user, { report_type: "order_cycle_customer_totals" }, true)
      OpenFoodNetwork::OrderGrouper.new(report.rules, report.columns).table(report.table_items)
    }

    it "has a product row" do
      product_name_field = items.first[5]
      expect(product_name_field).to eq product.name
    end

    it "has a summary row" do
      product_name_field = items.last[5]
      expect(product_name_field).to eq "TOTAL"
    end

    it "contain the right SKU" do
      sku_field = items.first[23]
      expect(sku_field).to eq product.sku
    end
  end
end
