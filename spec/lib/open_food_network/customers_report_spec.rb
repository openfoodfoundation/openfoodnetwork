require 'spec_helper'

module OpenFoodNetwork
  describe CustomersReport do
    context "As a site admin" do
      let(:user) do 
        user = create(:user)
        user.spree_roles << Spree::Role.find_or_create_by_name!("admin")
        user
      end
      subject { CustomersReport.new user }

      context "a mailing list" do
        before do
          subject.stub(:params).and_return(report_type: "mailing_list")
        end

        it "returns headers for mailing_list" do
          subject.header.should == ["Email", "First Name", "Last Name", "Suburb"]
        end

        it "should build a table from a list of variants" do
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

      context "an addresses report" do
        before do
          subject.stub(:params).and_return(report_type: "addresses")
        end
        it "returns headers for addresses" do
          subject.header.should == ["First Name", "Last Name", "Billing Address", "Email", "Phone", "Hub", "Hub Address", "Shipping Method"]
        end

        it "should build a table from a list of variants" do
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

      describe "Fetching orders" do
        it "should fetch complete orders" do
          o1 = create(:order)
          o2 = create(:order, completed_at: 1.day.ago)
          subject.orders.should == [o2]
        end
        it "not show cancelled orders" do
          o1 = create(:order, state: "canceled", completed_at: 1.day.ago)
          o2 = create(:order, completed_at: 1.day.ago)
          subject.orders.should == [o2]
        end
      end
    end
    context "As an enterprise user" do
      let(:user) do 
        user = create(:user)
        user.spree_roles = []
        user.save!
        user
      end
      subject { CustomersReport.new user }
      describe "Fetching orders" do
        it "should only show orders managed by the current user" do
          d1 = create(:distributor_enterprise)
          d1.enterprise_roles.build(user: user).save
          d2 = create(:distributor_enterprise)
          d2.enterprise_roles.build(user: create(:user)).save

          o1 = create(:order, distributor: d1, completed_at: 1.day.ago)
          o2 = create(:order, distributor: d2, completed_at: 1.day.ago)

          subject.orders.should == [o1]
        end
      end
    end
  end
end
