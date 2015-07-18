require 'spec_helper'

include AuthenticationWorkflow

module OpenFoodNetwork
  describe BulkCoopReport do
    context "as a site admin" do
      let(:user) do
        user = create(:user)
        user.spree_roles << Spree::Role.find_or_create_by_name!("admin")
        user
      end
      subject { BulkCoopReport.new user }

      describe "fetching orders" do
        it "fetches completed orders" do
          o1 = create(:order)
          o2 = create(:order, completed_at: 1.day.ago)
          subject.orders.should == [o2]
        end

        it "does not show cancelled orders" do
          o1 = create(:order, state: "canceled", completed_at: 1.day.ago)
          o2 = create(:order, completed_at: 1.day.ago)
          subject.orders.should == [o2]
        end
      end
    end

    context "as an enterprise user" do
      let!(:user) { create_enterprise_user }

      subject { BulkCoopReport.new user }

      describe "fetching orders" do
        let(:supplier) { create(:supplier_enterprise) }
        let(:product) { create(:simple_product, supplier: supplier) }
        let(:oc1) { create(:simple_order_cycle) }
        let(:order) { create(:order, completed_at: 1.day.ago, order_cycle: oc1) }
        let(:distributor) { create(:distributor_enterprise) }
        let(:d2) { create(:distributor_enterprise) }

        it "only shows orders managed by the current user" do
          distributor.enterprise_roles.create!(user: user)
          d2.enterprise_roles.create!(user: create(:user))

          o1 = create(:order, distributor: distributor, completed_at: 1.day.ago)
          o2 = create(:order, distributor: d2, completed_at: 1.day.ago)

          subject.orders.should == [o1]
        end

        it "only shows product line items that I am supplying" do
          distributor.enterprise_roles.create!(user: user)
          create(:enterprise_relationship, parent: supplier, child: distributor, permissions_list: [:add_to_order_cycle])
          d2.enterprise_roles.create!(user: create(:user))

          s2 = create(:supplier_enterprise)
          p2 = create(:simple_product, supplier: s2)

          li1 = create(:line_item, product: product)
          li2 = create(:line_item, product: p2)
          o1 = create(:order, distributor: distributor, completed_at: 1.day.ago)
          o1.line_items << li1
          o2 = create(:order, distributor: d2, completed_at: 1.day.ago)
          o2.line_items << li2
          subject.orders.map{ |o| o.line_items}.flatten.should include li1
          subject.orders.map{ |o| o.line_items}.flatten.should_not include li2

        end
      end
    end
  end
end
