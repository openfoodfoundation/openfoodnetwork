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
          supplier.enterprise_roles.create(user: user)
          order.line_items << create(:line_item, product: product)

          # When I fetch orders, I should see no orders
          subject.should_receive(:filter).with([]).and_return([])
          subject.orders.should == []
        end
      end
    end

    context "as an enterprise user" do
      let!(:user) { create_enterprise_user }
      subject { OrderCycleManagementReport.new user }

      describe "filtering orders" do

        let(:supplier) { create(:supplier_enterprise) }
        let(:order) { create(:order, completed_at: 1.day.ago) }


        it "returns all orders sans-params" do
          orders = Spree::Order.scoped
          subject.filter(orders).should == orders
        end

        #orders = 2 orders, subject.orders = []. Why is second empty?
        it "searches to a specific order cycle" do
          s1 = create(:distributor_enterprise)
          s1.enterprise_roles.create!(user: user)

          oc1 = create(:simple_order_cycle)
          oc2 = create(:simple_order_cycle)
          order1 = create(:order, distributor: s1, order_cycle: oc1, completed_at: 1.day.ago)
          order2 = create(:order, distributor: s1, order_cycle: oc2, completed_at: 1.day.ago)

          subject.stub(:params).and_return(q: {order_cycle_id_eq: oc1.id} )
          subject.should_receive(:filter).with([order1]).and_return([order1])
          subject.orders.should == [order1]
        end

        it "filters to a payment method" do
          orders = Spree::Order.scoped
          pm1 = create(:payment_method, name: "PM1")
          order1 = create(:order)
          payment1 = create(:payment, order: order1, payment_method: pm1)
          pm2 = create(:payment_method, name: "PM2")
          order2 = create(:order)
          payment2 = create(:payment, order: order2, payment_method: pm2)
          subject.stub(:params).and_return(payment_method_in: pm1.name)
          subject.filter(orders).should == [order1]
        end

        it "filters to a shipping method" do
          orders = Spree::Order.scoped
          sm1 = create(:shipping_method, name: "ship1")
          order1 = create(:order, shipping_method: sm1)
          sm2 = create(:shipping_method, name: "ship2")
          order2 = create(:order, shipping_method: sm2)

          subject.stub(:params).and_return(shipping_method_in: sm1.name)
          subject.filter(orders).should == [order1]
        end

        it "should do all the filters at once" do

          s1 = create(:distributor_enterprise)
          s1.enterprise_roles.create!(user: user)

          oc1 = create(:simple_order_cycle)
          oc2 = create(:simple_order_cycle)
          pm1 = create(:payment_method, name: "PM1")
          pm2 = create(:payment_method, name: "PM2")
          sm1 = create(:shipping_method, name: "ship1")
          sm2 = create(:shipping_method, name: "ship2")
          order1 = create(:order, distributor: s1, order_cycle: oc1, shipping_method: sm1, completed_at: 1.day.ago)
          payment1 = create(:payment, order: order1, payment_method: pm1)
          order2 = create(:order, distributor: s1, order_cycle: oc2,  shipping_method: sm2, completed_at: 1.day.ago)
          payment2 = create(:payment, order: order2, payment_method: pm2)


          subject.stub(:params).and_return(q: {order_cycle_id_eq: oc1.id},
                                           shipping_method_in: sm1.name,
                                           payment_method_in: pm1.name)

          subject.should_receive(:filter).with([order1]).and_return([order1])
          subject.orders.should == [order1]

        end
      end
    end
  end
end
