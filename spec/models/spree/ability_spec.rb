require 'spec_helper'
require "cancan/matchers"
require 'support/cancan_helper'

module Spree

  describe User do

    describe "broad permissions" do
      subject { AbilityDecorator.new(user) }
      let(:user) { create(:user) }
      let(:enterprise_any) { create(:enterprise, sells: 'any') }
      let(:enterprise_own) { create(:enterprise, sells: 'own') }
      let(:enterprise_none) { create(:enterprise, sells: 'none') }

      context "as manager of a 'any' type enterprise" do
        before do
          user.enterprise_roles.create! enterprise: enterprise_any
        end

        it { subject.can_manage_products?(user).should be_true }
        it { subject.can_manage_enterprises?(user).should be_true }
        it { subject.can_manage_orders?(user).should be_true }
      end

      context "as manager of a 'own' type enterprise" do
        before do
          user.enterprise_roles.create! enterprise: enterprise_own
        end

        it { subject.can_manage_products?(user).should be_true }
        it { subject.can_manage_enterprises?(user).should be_true }
        it { subject.can_manage_orders?(user).should be_true }
      end

      context "as manager of a 'none' type enterprise" do
        before do
          user.enterprise_roles.create! enterprise: enterprise_none
        end

        it { subject.can_manage_products?(user).should be_true }
        it { subject.can_manage_enterprises?(user).should be_true }
        it { subject.can_manage_orders?(user).should be_false }
      end

      context "as a new user with no enterprises" do
        it { subject.can_manage_products?(user).should be_false }
        it { subject.can_manage_enterprises?(user).should be_false }
        it { subject.can_manage_orders?(user).should be_false }

        it "can create enterprises straight off the bat" do
          subject.is_new_user?(user).should be_true
          expect(user).to have_ability :create, for: Enterprise
        end
      end
    end

    describe 'Roles' do

      # create enterprises
      let(:s1) { create(:supplier_enterprise) }
      let(:s2) { create(:supplier_enterprise) }
      let(:s_related) { create(:supplier_enterprise) }
      let(:d1) { create(:distributor_enterprise) }
      let(:d2) { create(:distributor_enterprise) }

      let(:p1) { create(:product, supplier: s1, distributors:[d1, d2]) }
      let(:p2) { create(:product, supplier: s2, distributors:[d1, d2]) }
      let(:p_related) { create(:product, supplier: s_related) }

      let(:er1) { create(:enterprise_relationship, parent: s1, child: d1) }
      let(:er2) { create(:enterprise_relationship, parent: d1, child: s1) }
      let(:er_p) { create(:enterprise_relationship, parent: s_related, child: s1, permissions_list: [:manage_products]) }

      subject { user }
      let(:user) { nil }

      context "when is a supplier enterprise user" do
        # create supplier_enterprise1 user without full admin access
        let(:user) do
          user = create(:user)
          user.spree_roles = []
          s1.enterprise_roles.build(user: user).save
          user
        end

        let(:order) {create(:order)}

        it "should be able to read/write their enterprises' products and variants" do
          should have_ability([:admin, :read, :update, :product_distributions, :bulk_edit, :bulk_update, :clone, :destroy], for: p1)
          should have_ability([:admin, :index, :read, :edit, :update, :search, :destroy], for: p1.master)
        end

        it "should be able to read/write related enterprises' products and variants with manage_products permission" do
          er_p
          should have_ability([:admin, :read, :update, :product_distributions, :bulk_edit, :bulk_update, :clone, :destroy], for: p_related)
          should have_ability([:admin, :index, :read, :edit, :update, :search, :destroy], for: p_related.master)
        end

        it "should not be able to read/write other enterprises' products and variants" do
          should_not have_ability([:admin, :read, :update, :product_distributions, :bulk_edit, :bulk_update, :clone, :destroy], for: p2)
          should_not have_ability([:admin, :index, :read, :edit, :update, :search, :destroy], for: p2.master)
        end

        it "should not be able to access admin actions on orders" do
          should_not have_ability([:admin], for: Spree::Order)
        end

        it "should be able to create a new product" do
          should have_ability(:create, for: Spree::Product)
        end

        it "should be able to read/write their enterprises' product variants" do
          should have_ability([:create], for: Spree::Variant)
          should have_ability([:admin, :index, :read, :create, :edit, :search, :update, :destroy], for: p1.master)
        end

        it "should not be able to read/write other enterprises' product variants" do
          should_not have_ability([:admin, :index, :read, :create, :edit, :search, :update, :destroy], for: p2.master)
        end

        it "should be able to read/write their enterprises' product properties" do
          should have_ability([:admin, :index, :read, :create, :edit, :update_positions, :destroy], for: Spree::ProductProperty)
        end

        it "should be able to read/write their enterprises' product images" do
          should have_ability([:admin, :index, :read, :create, :edit, :update, :destroy], for: Spree::Image)
        end

        it "should be able to read Taxons (in order to create classifications)" do
          should have_ability([:admin, :index, :read, :search], for: Spree::Taxon)
        end

        it "should be able to read/write Classifications on a product" do
          should have_ability([:admin, :index, :read, :create, :edit], for: Spree::Classification)
        end

        it "should be able to read/write their enterprises' producer properties" do
          should have_ability([:admin, :index, :read, :create, :edit, :update_positions, :destroy], for: ProducerProperty)
        end

        it "should be able to read and create enterprise relationships" do
          should have_ability([:admin, :index, :create], for: EnterpriseRelationship)
        end

        it "should be able to destroy enterprise relationships for its enterprises" do
          should have_ability(:destroy, for: er1)
        end

        it "should not be able to destroy enterprise relationships for other enterprises" do
          should_not have_ability(:destroy, for: er2)
        end

      end

      context "when is a distributor enterprise user" do
        # create distributor_enterprise1 user without full admin access
        let (:user) do
          user = create(:user)
          user.spree_roles = []
          d1.enterprise_roles.build(user: user).save
          user
        end
        # create order for each enterprise
        let(:o1) do
          o = create(:order, distributor: d1, bill_address: create(:address))
          create(:line_item, order: o, product: p1)
          o
        end
        let(:o2) do
          o = create(:order, distributor: d2, bill_address: create(:address))
          create(:line_item, order: o, product: p1)
          o
        end
        let(:o3) do
          o = create(:order, distributor: nil, bill_address: create(:address))
          create(:line_item, order: o, product: p1)
          o
        end

        it "should be able to read/write their enterprises' orders" do
          should have_ability([:admin, :index, :read, :edit], for: o1)
        end

        it "should not be able to read/write other enterprises' orders" do
          should_not have_ability([:admin, :index, :read, :edit], for: o2)
        end

        it "should be able to read/write orders that are in the process of being created" do
          should have_ability([:admin, :index, :read, :edit], for: o3)
        end

        it "should be able to create and search on nil (required for creating an order)" do
          should have_ability([:create, :search], for: nil)
        end

        it "should be able to create a new order" do
          should have_ability([:admin, :index, :read, :create, :update], for: Spree::Order)
        end

        it "should be able to create a new line item" do
          should have_ability([:admin, :create], for: Spree::LineItem)
        end

        it "should be able to read/write Payments on a product" do
          should have_ability([:admin, :index, :read, :create, :edit, :update, :fire], for: Spree::Payment)
        end

        it "should be able to read/write Shipments on a product" do
          should have_ability([:admin, :index, :read, :create, :edit, :update, :fire], for: Spree::Shipment)
        end

        it "should be able to read/write Adjustments on a product" do
          should have_ability([:admin, :index, :read, :create, :edit, :update, :fire], for: Spree::Adjustment)
        end

        it "should be able to read/write ReturnAuthorizations on a product" do
          should have_ability([:admin, :index, :read, :create, :edit, :update, :fire], for: Spree::ReturnAuthorization)
        end

        it "should be able to read/write PaymentMethods" do
          should have_ability([:admin, :index, :create, :update, :destroy], for: Spree::PaymentMethod)
        end

        it "should be able to read/write ShippingMethods" do
          should have_ability([:admin, :index, :create, :update, :destroy], for: Spree::ShippingMethod)
        end

        it "should be able to read and create enterprise relationships" do
          should have_ability([:admin, :index, :create], for: EnterpriseRelationship)
        end

        it "should be able to destroy enterprise relationships for its enterprises" do
          should have_ability(:destroy, for: er2)
        end

        it "should not be able to destroy enterprise relationships for other enterprises" do
          should_not have_ability(:destroy, for: er1)
        end
      end

      context 'Order Cycle co-ordinator, distriutor enterprise manager' do
        let (:user) do
          user = create(:user)
          user.spree_roles = []
          d1.enterprise_roles.build(user: user).save
          user
        end

        let(:oc1) { create(:simple_order_cycle, {coordinator: d1}) }
        let(:oc2) { create(:simple_order_cycle) }

        it "should be able to read/write OrderCycles they are the co-ordinator of" do
          should have_ability([:admin, :index, :read, :edit, :update, :clone], for: oc1)
        end

        it "should not be able to read/write OrderCycles they are not the co-ordinator of" do
          should_not have_ability([:admin, :index, :read, :create, :edit, :update, :clone], for: oc2)
        end

        it "should be able to create OrderCycles" do
          should have_ability([:create], for: OrderCycle)
        end

        it "should be able to read/write EnterpriseFees" do
          should have_ability([:admin, :index, :read, :create, :edit, :bulk_update, :destroy], for: EnterpriseFee)
        end

        #TODO clarify :for_order_cycle and its purpose - and possibly rename it.
        it "should be able to do something with order cycles (??)" do
          should have_ability([:for_order_cycle], Enterprise)
        end
      end

      context 'enterprise manager' do
        let (:user) do
          user = create(:user)
          user.spree_roles = []
          s1.enterprise_roles.build(user: user).save
          user
        end

        it 'should have the ability to read and edit enterprises that I manage' do
          should have_ability([:read, :edit, :update, :bulk_update], for: s1)
        end

        it 'should not have the ability to read and edit enterprises that I do not manage' do
          should_not have_ability([:read, :edit, :update, :bulk_update], for: s2)
        end

        it 'should have the ability administrate and create enterpises' do
          should have_ability([:admin, :index, :create], for: Enterprise)
        end
      end
    end
  end
end
