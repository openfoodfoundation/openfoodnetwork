require 'spec_helper'

include AuthenticationWorkflow

module OpenFoodNetwork
  describe PackingReport do
    context "as a site admin" do
      let(:user) do
        user = create(:user)
        user.spree_roles << Spree::Role.find_or_create_by_name!("admin")
        user
      end
      subject { PackingReport.new user }

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

      subject { PackingReport.new user }

      describe "fetching orders" do
        let(:supplier) { create(:supplier_enterprise) }
        let(:product) { create(:simple_product, supplier: supplier) }
        let(:d1) { create(:distributor_enterprise) }
        let(:oc1) { create(:simple_order_cycle) }
        let(:order) { create(:order, completed_at: 1.day.ago, order_cycle: oc1, distributor: d1) }

        before do
          d1.enterprise_roles.create!(user: user)
        end

        it "only shows orders managed by the current user" do
          d2 = create(:distributor_enterprise)
          d2.enterprise_roles.create!(user: create(:user))
          o2 = create(:order, distributor: d2, completed_at: 1.day.ago)

          subject.orders.should == [order]
        end

        it "only shows the selected order cycle" do
          oc2 = create(:simple_order_cycle)
          order2 = create(:order, order_cycle: oc2)
          subject.stub(:params).and_return(order_cycle_id_in: oc1.id)
          subject.orders.should == [order]
        end

        it "only shows product line items that I am supplying" do
          d2 = create(:distributor_enterprise)
          create(:enterprise_relationship, parent: supplier, child: d1, permissions_list: [:add_to_order_cycle])
          d2.enterprise_roles.create!(user: create(:user))

          s2 = create(:supplier_enterprise)
          p2 = create(:simple_product, supplier: s2)

          li1 = create(:line_item, product: product)
          li2 = create(:line_item, product: p2)
          o1 = create(:order, distributor: d1, completed_at: 1.day.ago)
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
