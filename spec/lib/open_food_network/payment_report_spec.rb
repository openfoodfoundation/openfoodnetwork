require 'spec_helper'

include AuthenticationWorkflow

module OpenFoodNetwork
  describe PaymentsReport do
    context "as a site admin" do
      let(:user) do
        user = create(:user)
        user.spree_roles << Spree::Role.find_or_create_by_name!("admin")
        user
      end
      
      subject { PaymentsReport.new user }

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

      subject { PaymentsReport.new user }

      describe "fetching orders" do
        let(:supplier) { create(:supplier_enterprise) }
        let(:product) { create(:simple_product, supplier: supplier) }
        let(:order) { create(:order, completed_at: 1.day.ago) }

        it "only shows orders that I have access to" do
          d1 = create(:distributor_enterprise)
          d1.enterprise_roles.create!(user: user)
          d2 = create(:distributor_enterprise)
          d2.enterprise_roles.create!(user: create(:user))

          o1 = create(:order, distributor: d1, completed_at: 1.day.ago)
          o2 = create(:order, distributor: d2, completed_at: 1.day.ago)

          subject.orders.should == [o1]
        end
      end
    end
  end
end
