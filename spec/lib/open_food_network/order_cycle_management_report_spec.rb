require 'spec_helper'

include AuthenticationWorkflow

module OpenFoodNetwork
  describe OrderCycleManagementReport do
    context "as a site admin" do
      let(:user) do
        user = create(:user)
        user.spree_roles << Spree::Role.find_or_create_by_name!("admin")
        user
      end
      subject { OrderCycleManagementReport.new user }

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

      subject { OrderCycleManagementReport.new user }

      describe "fetching orders" do
        let(:supplier) { create(:supplier_enterprise) }
        let(:product) { create(:simple_product, supplier: supplier) }
        let(:order) { create(:order, completed_at: 1.day.ago) }

        it "only shows orders managed by the current user" do
          d1 = create(:distributor_enterprise)
          d1.enterprise_roles.create!(user: user)
          d2 = create(:distributor_enterprise)
          d2.enterprise_roles.create!(user: create(:user))

          o1 = create(:order, distributor: d1, completed_at: 1.day.ago)
          o2 = create(:order, distributor: d2, completed_at: 1.day.ago)

          subject.should_receive(:filter).with([o1]).and_return([o1])
          subject.orders.should == [o1]
        end


        it "does not show orders through a hub that the current user does not manage" do
          # Given a supplier enterprise with an order for one of its products
          supplier.enterprise_roles.create!(user: user)
          order.line_items << create(:line_item, product: product)

          # When I fetch orders, I should see no orders
          subject.should_receive(:filter).with([]).and_return([])
          subject.orders.should == []
        end
      end

      describe "filtering orders" do
        let!(:orders) { Spree::Order.scoped }
        let!(:supplier) { create(:supplier_enterprise) }

        let!(:oc1) { create(:simple_order_cycle) }
        let!(:pm1) { create(:payment_method, name: "PM1") }
        let!(:sm1) { create(:shipping_method, name: "ship1") }
        let!(:order1) { create(:order, shipping_method: sm1, order_cycle: oc1) }
        let!(:payment1) { create(:payment, order: order1, payment_method: pm1) }

        it "returns all orders sans-params" do
          subject.filter(orders).should == orders
        end

        it "filters to a specific order cycle" do
          oc2 = create(:simple_order_cycle)
          order2 = create(:order, order_cycle: oc2)

          subject.stub(:params).and_return(order_cycle_id: oc1.id)
          subject.filter(orders).should == [order1]
        end

        it "filters to a payment method" do
          pm2 = create(:payment_method, name: "PM2")
          pm3 = create(:payment_method, name: "PM3")
          order2 = create(:order, payments: [create(:payment, payment_method: pm2)])
          order3 = create(:order, payments: [create(:payment, payment_method: pm3)])
          # payment2 = create(:payment, order: order2, payment_method: pm2)

          subject.stub(:params).and_return(payment_method_in: [pm1.id, pm3.id] )
          subject.filter(orders).should match_array [order1, order3]
        end

        it "filters to a shipping method" do
          sm2 = create(:shipping_method, name: "ship2")
          sm3 = create(:shipping_method, name: "ship3")
          order2 = create(:order, shipping_method: sm2)
          order3 = create(:order, shipping_method: sm3)

          subject.stub(:params).and_return(shipping_method_in: [sm1.id, sm3.id])
          expect(subject.filter(orders)).to match_array [order1, order3]
        end

        it "should do all the filters at once" do
          subject.stub(:params).and_return(order_cycle_id: oc1.id,
                                           shipping_method_name: sm1.name,
                                           payment_method_name: pm1.name)
          subject.filter(orders).should == [order1]
        end
      end
    end
  end
end
