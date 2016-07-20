require 'spec_helper'

include AuthenticationWorkflow

module OpenFoodNetwork
  describe OrdersAndFulfillmentsReport do
    describe "fetching orders" do
      let(:d1) { create(:distributor_enterprise) }
      let(:oc1) { create(:simple_order_cycle) }
      let(:o1) { create(:order, completed_at: 1.day.ago, order_cycle: oc1, distributor: d1) }
      let(:li1) { build(:line_item) }

      before { o1.line_items << li1 }

      context "as a site admin" do
        let(:user) { create(:admin_user) }
        subject { PackingReport.new user }

        it "fetches completed orders" do
          o2 = create(:order)
          o2.line_items << build(:line_item)
          subject.table_items.should == [li1]
        end

        it "does not show cancelled orders" do
          o2 = create(:order, state: "canceled", completed_at: 1.day.ago)
          o2.line_items << build(:line_item)
          subject.table_items.should == [li1]
        end
      end

      context "as a manager of a supplier" do
        let!(:user) { create(:user) }
        subject { OrdersAndFulfillmentsReport.new user }

        let(:s1) { create(:supplier_enterprise) }

        before do
          s1.enterprise_roles.create!(user: user)
        end

        context "that has granted P-OC to the distributor" do
          let(:o2) { create(:order, distributor: d1, completed_at: 1.day.ago, bill_address: create(:address), ship_address: create(:address)) }
          let(:li2) { build(:line_item, product: create(:simple_product, supplier: s1)) }

          before do
            o2.line_items << li2
            create(:enterprise_relationship, parent: s1, child: d1, permissions_list: [:add_to_order_cycle])
          end

          it "shows line items supplied by my producers, with names hidden" do
            subject.table_items.should == [li2]
            subject.table_items.first.order.bill_address.firstname.should == "HIDDEN"
          end
        end

        context "that has not granted P-OC to the distributor" do
          let(:o2) { create(:order, distributor: d1, completed_at: 1.day.ago, bill_address: create(:address), ship_address: create(:address)) }
          let(:li2) { build(:line_item, product: create(:simple_product, supplier: s1)) }

          before do
            o2.line_items << li2
          end

          it "shows line items supplied by my producers, with names hidden" do
            subject.table_items.should == []
          end
        end
      end

      context "as a manager of a distributor" do
        let!(:user) { create(:user) }
        subject { OrdersAndFulfillmentsReport.new user }

        before do
          d1.enterprise_roles.create!(user: user)
        end

        it "only shows line items distributed by enterprises managed by the current user" do
          d2 = create(:distributor_enterprise)
          d2.enterprise_roles.create!(user: create(:user))
          o2 = create(:order, distributor: d2, completed_at: 1.day.ago)
          o2.line_items << build(:line_item)
          subject.table_items.should == [li1]
        end

        it "only shows the selected order cycle" do
          oc2 = create(:simple_order_cycle)
          o2 = create(:order, distributor: d1, order_cycle: oc2)
          o2.line_items << build(:line_item)
          subject.stub(:params).and_return(order_cycle_id_in: oc1.id)
          subject.table_items.should == [li1]
        end
      end
    end

    describe "columns are aligned" do
      let(:d1) { create(:distributor_enterprise) }
      let(:oc1) { create(:simple_order_cycle) }
      let(:o1) { create(:order, completed_at: 1.day.ago, order_cycle: oc1, distributor: d1) }
      let(:li1) { build(:line_item) }
      let(:user) { create(:admin_user)}

      before { o1.line_items << li1 }

      it 'has aligned columsn' do
        report_types = ["", "order_cycle_supplier_totals", "order_cycle_supplier_totals_by_distributor", "order_cycle_distributor_totals_by_supplier", "order_cycle_customer_totals"]

        report_types.each do |report_type|
          report = OrdersAndFulfillmentsReport.new user, report_type: report_type
          report.header.size.should == report.columns.size
        end
      end
    end
  end
end
