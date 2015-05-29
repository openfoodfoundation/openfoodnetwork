require 'spec_helper'

module OpenFoodNetwork
  describe CustomersReport do
    context "as a site admin" do
      let(:user) do
        user = create(:user)
        user.spree_roles << Spree::Role.find_or_create_by_name!("admin")
        user
      end
      subject { CustomersReport.new user }

      describe "mailing list report" do
        before do
          subject.stub(:params).and_return(report_type: "mailing_list")
        end

        it "returns headers for mailing_list" do
          subject.header.should == ["Email", "First Name", "Last Name", "Suburb"]
        end

        it "builds a table from a list of variants" do
          order = double(:order, email: "test@test.com")
          address = double(:billing_address, firstname: "Firsty",
                           lastname: "Lasty", city: "Suburbia")
          order.stub(:billing_address).and_return address
          subject.stub(:orders).and_return [order]

          subject.table.should == [[
            "test@test.com", "Firsty", "Lasty", "Suburbia"
          ]]
        end
      end

      describe "addresses report" do
        before do
          subject.stub(:params).and_return(report_type: "addresses")
        end

        it "returns headers for addresses" do
          subject.header.should == ["First Name", "Last Name", "Billing Address", "Email", "Phone", "Hub", "Hub Address", "Shipping Method"]
        end

        it "builds a table from a list of variants" do
          a = create(:address)
          d = create(:distributor_enterprise)
          o = create(:order, distributor: d, bill_address: a)
          o.shipping_method = create(:shipping_method)

          subject.stub(:orders).and_return [o]
          subject.table.should == [[
            a.firstname, a.lastname,
            [a.address1, a.address2, a.city].join(" "),
            o.email, a.phone, d.name,
            [d.address.address1, d.address.address2, d.address.city].join(" "),
            o.shipping_method.name
          ]]
        end
      end

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
      let(:user) do
        user = create(:user)
        user.spree_roles = []
        user.save!
        user
      end

      subject { CustomersReport.new user }

      describe "fetching orders" do
        let(:supplier) { create(:supplier_enterprise) }
        let(:product) { create(:simple_product, supplier: supplier) }
        let(:order) { create(:order, completed_at: 1.day.ago) }

        it "only shows orders managed by the current user" do
          d1 = create(:distributor_enterprise)
          d1.enterprise_roles.build(user: user).save
          d2 = create(:distributor_enterprise)
          d2.enterprise_roles.build(user: create(:user)).save

          o1 = create(:order, distributor: d1, completed_at: 1.day.ago)
          o2 = create(:order, distributor: d2, completed_at: 1.day.ago)

          subject.should_receive(:filter).with([o1]).and_return([o1])
          subject.orders.should == [o1]
        end

        it "does not show orders through a hub that the current user does not manage" do
          # Given a supplier enterprise with an order for one of its products
          supplier.enterprise_roles.build(user: user).save
          order.line_items << create(:line_item, product: product)

          # When I fetch orders, I should see no orders
          subject.should_receive(:filter).with([]).and_return([])
          subject.orders.should == []
        end
      end

      describe "filtering orders" do
        let(:orders) { Spree::Order.scoped }
        let(:supplier) { create(:supplier_enterprise) }

        it "returns all orders sans-params" do
          subject.filter(orders).should == orders
        end

        it "returns orders with a specific supplier" do
          supplier = create(:supplier_enterprise)
          supplier2 = create(:supplier_enterprise)
          product1 = create(:simple_product, supplier: supplier)
          product2 = create(:simple_product, supplier: supplier2)
          order1 = create(:order)
          order2 = create(:order)
          order1.line_items << create(:line_item, product: product1)
          order2.line_items << create(:line_item, product: product2)

          subject.stub(:params).and_return(supplier_id: supplier.id)
          subject.filter(orders).should == [order1]
        end

        it "filters to a specific distributor" do
          d1 = create(:distributor_enterprise)
          d2 = create(:distributor_enterprise)
          order1 = create(:order, distributor: d1)
          order2 = create(:order, distributor: d2)

          subject.stub(:params).and_return(distributor_id: d1.id)
          subject.filter(orders).should == [order1]
        end

        it "filters to a specific cycle" do
          oc1 = create(:simple_order_cycle)
          oc2 = create(:simple_order_cycle)
          order1 = create(:order, order_cycle: oc1)
          order2 = create(:order, order_cycle: oc2)

          subject.stub(:params).and_return(order_cycle_id: oc1.id)
          subject.filter(orders).should == [order1]
        end
      end
    end
  end
end
