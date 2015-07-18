require 'spec_helper'

include AuthenticationWorkflow

module OpenFoodNetwork

  describe OrdersAndFulfillmentsReport do

    # Given two distributors and two suppliers
    let!(:ba) { create(:address) }
    let!(:si) { "pick up on thursday please" }
    let!(:c1) { create(:distributor_enterprise) }
    let!(:c2) { create(:distributor_enterprise) }
    let!(:s1) { create(:supplier_enterprise) }
    let!(:s2) { create(:supplier_enterprise) }
    let!(:s3) { create(:supplier_enterprise) }
    let!(:d1) { create(:distributor_enterprise) }
    let!(:d2) { create(:distributor_enterprise) }
    let!(:d3) { create(:distributor_enterprise) }
    let!(:p1) { create(:product, price: 12.34, distributors: [d1], supplier: s1) }
    let!(:p2) { create(:product, price: 23.45, distributors: [d2], supplier: s2) }
    let!(:p3) { create(:product, price: 34.56, distributors: [d3], supplier: s3) }

    # Given two order cycles with both distributors
    let!(:ocA) { create(:simple_order_cycle, coordinator: c1, distributors: [d1, d2], suppliers: [s1, s2, s3], variants: [p1.master, p3.master]) }
    let!(:ocB) { create(:simple_order_cycle, coordinator: c2, distributors: [d1, d2], suppliers: [s1, s2, s3], variants: [p2.master]) }

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

    context "as a supplier user" do
      let!(:user) { create_enterprise_user }

      subject { OrdersAndFulfillmentsReport.new user }

      before do
        s1.enterprise_roles.create!(user: user)
      end

      context "where I have granted P-OC to the distributor" do

        before do
          create(:enterprise_relationship, parent: s1, child: d1, permissions_list: [:add_to_order_cycle])
        end

        it "only shows product line items that I am supplying" do
          subject.line_items.map(&:product).should include p1
          subject.line_items.map(&:product).should_not include p2, p3
        end

        it "only shows the selected order cycle" do
          subject.stub(:params).and_return(q: {order_cycle_id_eq: ocA.id} )
          subject.line_items.map(&:order).should include(orderA1)
          subject.line_items.map(&:order).should_not include(orderB1)
        end
      end

      context "where I have not granted P-OC to the distributor" do
        it "does not show me line_items I supply" do
          subject.line_items.map(&:product).should_not include p1, p2, p3
        end
      end
    end

    context "as a Coordinator Enterprise User" do
      let!(:user2) { create_enterprise_user }
      subject { OrdersAndFulfillmentsReport.new user2 }

      before do
        c1.enterprise_roles.create!(user: user2)
      end

      context "managing orders" do
        it "show all orders in order cycles I coordinate" do
          subject.line_items.map(&:order).should include orderA1, orderA2
          subject.line_items.map(&:order).should_not include orderB1, orderB2
        end
      end
    end

    context "Distributor Enterprise User" do
      let!(:user3) { create_enterprise_user }

      subject { OrdersAndFulfillmentsReport.new user3 }

      before do
        d1.enterprise_roles.create!(user: user3)
      end

      context 'managing orders' do
        it "only shows orders that I distribute" do
          subject.line_items.map(&:order).should include orderA1, orderB1
          subject.line_items.map(&:order).should_not include orderA2, orderB2
        end

        it "only shows the selected order cycle" do
          subject.stub(:params).and_return( q: { order_cycle_id_eq: ocA.id } )
          subject.line_items.map(&:order).should include(orderA1)
          subject.line_items.map(&:order).should_not include(orderB1)
        end
      end
    end
  end
end
