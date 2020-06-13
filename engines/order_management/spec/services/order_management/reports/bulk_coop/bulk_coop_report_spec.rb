# frozen_string_literal: true

require 'spec_helper'

describe OrderManagement::Reports::BulkCoop::BulkCoopReport do
  describe "fetching orders" do
    let(:d1) { create(:distributor_enterprise) }
    let(:oc1) { create(:simple_order_cycle) }
    let(:o1) { create(:order, completed_at: 1.day.ago, order_cycle: oc1, distributor: d1) }
    let(:li1) { build(:line_item_with_shipment) }

    before { o1.line_items << li1 }

    context "as a site admin" do
      let(:user) { create(:admin_user) }
      subject { OrderManagement::Reports::BulkCoop::BulkCoopReport.new user, {}, true }

      it "fetches completed orders" do
        o2 = create(:order)
        o2.line_items << build(:line_item)
        expect(subject.table_items).to eq([li1])
      end

      it "does not show cancelled orders" do
        o2 = create(:order, state: "canceled", completed_at: 1.day.ago)
        o2.line_items << build(:line_item_with_shipment)
        expect(subject.table_items).to eq([li1])
      end
    end

    context "as a manager of a supplier" do
      let!(:user) { create(:user) }
      subject { OrderManagement::Reports::BulkCoop::BulkCoopReport.new user, {}, true }

      let(:s1) { create(:supplier_enterprise) }

      before do
        s1.enterprise_roles.create!(user: user)
      end

      context "that has granted P-OC to the distributor" do
        let(:o2) do
          create(:order, distributor: d1, completed_at: 1.day.ago, bill_address: create(:address),
                         ship_address: create(:address))
        end
        let(:li2) do
          build(:line_item_with_shipment, product: create(:simple_product, supplier: s1))
        end

        before do
          o2.line_items << li2
          create(:enterprise_relationship, parent: s1, child: d1,
                                           permissions_list: [:add_to_order_cycle])
        end

        it "shows line items supplied by my producers, with names hidden" do
          expect(subject.table_items).to eq([li2])
          expect(subject.table_items.first.order.bill_address.firstname).to eq("HIDDEN")
        end
      end

      context "that has not granted P-OC to the distributor" do
        let(:o2) do
          create(:order, distributor: d1, completed_at: 1.day.ago, bill_address: create(:address),
                         ship_address: create(:address))
        end
        let(:li2) do
          build(:line_item_with_shipment, product: create(:simple_product, supplier: s1))
        end

        before do
          o2.line_items << li2
        end

        it "does not show line items supplied by my producers" do
          expect(subject.table_items).to eq([])
        end
      end
    end
  end
end
