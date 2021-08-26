# frozen_string_literal: true

require 'spec_helper'

describe "Packing Reports" do
  include AuthenticationHelper

  describe "fetching orders" do
    let(:distributor) { create(:distributor_enterprise) }
    let(:order_cycle) { create(:simple_order_cycle) }
    let(:order) {
      create(:order, completed_at: 1.day.ago, order_cycle: order_cycle, distributor: distributor)
    }
    let(:line_item) { build(:line_item_with_shipment) }

    before { order.line_items << line_item }

    context "as a site admin" do
      let(:user) { create(:admin_user) }
      subject { Reports::Packing::Customer.new user, {} }

      it "fetches completed orders" do
        order2 = create(:order)
        order2.line_items << build(:line_item)
        expect(subject.collection).to eq([line_item])
      end

      it "does not show cancelled orders" do
        order2 = create(:order, state: "canceled", completed_at: 1.day.ago)
        order2.line_items << build(:line_item_with_shipment)
        expect(subject.collection).to eq([line_item])
      end
    end

    context "as a manager of a supplier" do
      let!(:user) { create(:user) }
      subject { Reports::Packing::Customer.new user, {} }

      let(:supplier) { create(:supplier_enterprise) }

      before do
        supplier.enterprise_roles.create!(user: user)
      end

      context "that has granted P-OC to the distributor" do
        let(:order2) {
          create(:order, distributor: distributor, completed_at: 1.day.ago,
                         bill_address: create(:address), ship_address: create(:address))
        }
        let(:line_item2) {
          build(:line_item_with_shipment, product: create(:simple_product, supplier: supplier))
        }

        before do
          order2.line_items << line_item2
          create(:enterprise_relationship, parent: supplier, child: distributor,
                                           permissions_list: [:add_to_order_cycle])
        end

        it "shows line items supplied by my producers, with names hidden" do
          expect(subject.collection).to eq([line_item2])
          expect(subject.as_json.first[:first_name]).to eq(
            I18n.t('admin.reports.hidden_field')
          )
        end
      end

      context "that has not granted P-OC to the distributor" do
        let(:order2) {
          create(:order, distributor: distributor, completed_at: 1.day.ago,
                         bill_address: create(:address), ship_address: create(:address))
        }
        let(:line_item2) {
          build(:line_item_with_shipment, product: create(:simple_product, supplier: supplier))
        }

        before do
          order2.line_items << line_item2
        end

        it "does not show line items supplied by my producers" do
          expect(subject.collection).to eq([])
        end
      end
    end

    context "as a manager of a distributor" do
      let!(:user) { create(:user) }
      subject { Reports::Packing::Customer.new user, {} }

      before do
        distributor.enterprise_roles.create!(user: user)
      end

      it "only shows line items distributed by enterprises managed by the current user" do
        distributor2 = create(:distributor_enterprise)
        distributor2.enterprise_roles.create!(user: create(:user))
        order2 = create(:order, distributor: distributor2, completed_at: 1.day.ago)
        order2.line_items << build(:line_item_with_shipment)
        expect(subject.collection).to eq([line_item])
      end

      it "only shows the selected order cycle" do
        order_cycle2 = create(:simple_order_cycle)
        order2 = create(:order, distributor: distributor, order_cycle: order_cycle2)
        order2.line_items << build(:line_item)
        allow(subject).to receive(:params).and_return(order_cycle_id_in: order_cycle.id)
        expect(subject.collection).to eq([line_item])
      end
    end
  end
end
