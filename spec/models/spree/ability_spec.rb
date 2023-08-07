# frozen_string_literal: true

require 'spec_helper'
require 'cancan/matchers'
require 'support/ability_helpers'

describe Spree::Ability do
  let(:user) { create(:user) }
  let(:subject) { Spree::Ability.new(user) }
  let(:token) { nil }

  before do
    user.spree_roles.clear
  end

  TOKEN = 'token123'

  after(:each) {
    user.spree_roles = []
  }

  context 'for general resource' do
    let(:resource) { Object.new }

    context 'with admin user' do
      before(:each) { allow(user).to receive(:has_spree_role?).and_return(true) }
      it_should_behave_like 'access granted'
      it_should_behave_like 'index allowed'
    end

    context 'with customer' do
      it_should_behave_like 'access denied'
      it_should_behave_like 'no index allowed'
    end
  end

  context 'for admin protected resources' do
    let(:resource) { Object.new }
    let(:resource_shipment) { Spree::Shipment.new }
    let(:resource_product) { Spree::Product.new }
    let(:resource_user) { Spree::User.new }
    let(:resource_order) { Spree::Order.new }
    let(:fakedispatch_user) { Spree::User.new }
    let(:fakedispatch_ability) { Spree::Ability.new(fakedispatch_user) }

    context 'with admin user' do
      it 'should be able to admin' do
        user.spree_roles << Spree::Role.find_or_create_by(name: 'admin')
        expect(subject).to be_able_to :admin, resource
        expect(subject).to be_able_to :index, resource_order
        expect(subject).to be_able_to :show, resource_product
        expect(subject).to be_able_to :create, resource_user
      end
    end

    context 'with customer' do
      it 'should not be able to admin' do
        expect(subject).to_not be_able_to :admin, resource
        expect(subject).to_not be_able_to :admin, resource_order
        expect(subject).to_not be_able_to :admin, resource_product
        expect(subject).to_not be_able_to :admin, resource_user
      end
    end
  end

  context 'as Guest User' do
    context 'for Country' do
      let(:resource) { Spree::Country.new }
      context 'requested by any user' do
        it_should_behave_like 'read only'
      end
    end

    context 'for Order' do
      let(:resource) { Spree::Order.new }

      context 'requested by same user' do
        before(:each) { resource.user = user }
        it_should_behave_like 'access granted'
        it_should_behave_like 'no index allowed'
      end

      context 'requested by other user' do
        before(:each) { resource.user = Spree::User.new }
        it_should_behave_like 'create only'
      end

      context 'requested with proper token' do
        let(:token) { 'TOKEN123' }
        before(:each) { allow(resource).to receive_messages token: 'TOKEN123' }
        it_should_behave_like 'access granted'
        it_should_behave_like 'no index allowed'
      end

      context 'requested with inproper token' do
        let(:token) { 'FAIL' }
        before(:each) { allow(resource).to receive_messages token: 'TOKEN123' }
        it_should_behave_like 'create only'
      end
    end

    context 'for Product' do
      let(:resource) { Spree::Product.new }
      context 'requested by any user' do
        it_should_behave_like 'read only'
      end
    end

    context 'for ProductProperty' do
      let(:resource) { Spree::Product.new }
      context 'requested by any user' do
        it_should_behave_like 'read only'
      end
    end

    context 'for Property' do
      let(:resource) { Spree::Product.new }
      context 'requested by any user' do
        it_should_behave_like 'read only'
      end
    end

    context 'for State' do
      let(:resource) { Spree::State.new }
      context 'requested by any user' do
        it_should_behave_like 'read only'
      end
    end

    context 'for StockItem' do
      let(:resource) { Spree::StockItem.new }
      context 'requested by any user' do
        it_should_behave_like 'read only'
      end
    end

    context 'for StockLocation' do
      let(:resource) { Spree::StockLocation.new }
      context 'requested by any user' do
        it_should_behave_like 'read only'
      end
    end

    context 'for StockMovement' do
      let(:resource) { Spree::StockMovement.new }
      context 'requested by any user' do
        it_should_behave_like 'read only'
      end
    end

    context 'for Taxons' do
      let(:resource) { Spree::Taxon.new }
      context 'requested by any user' do
        it_should_behave_like 'read only'
      end
    end

    context 'for Taxonomy' do
      let(:resource) { Spree::Taxonomy.new }
      context 'requested by any user' do
        it_should_behave_like 'read only'
      end
    end

    context 'for User' do
      context 'requested by same user' do
        let(:resource) { user }
        it_should_behave_like 'access granted'
        it_should_behave_like 'no index allowed'
      end
      context 'requested by other user' do
        let(:resource) { Spree::User.new }
        it_should_behave_like 'create only'
      end
    end

    context 'for Variant' do
      let(:resource) { Spree::Variant.new }
      context 'requested by any user' do
        it_should_behave_like 'read only'
      end
    end

    context 'for Zone' do
      let(:resource) { Spree::Zone.new }
      context 'requested by any user' do
        it_should_behave_like 'read only'
      end
    end
  end

  describe "broad permissions" do
    let(:user) { create(:user) }
    let(:enterprise_any) { create(:enterprise, sells: 'any') }
    let(:enterprise_own) { create(:enterprise, sells: 'own') }
    let(:enterprise_none) { create(:enterprise, sells: 'none') }
    let(:enterprise_any_producer) { create(:enterprise, sells: 'any', is_primary_producer: true) }
    let(:enterprise_own_producer) { create(:enterprise, sells: 'own', is_primary_producer: true) }
    let(:enterprise_none_producer) { create(:enterprise, sells: 'none', is_primary_producer: true) }

    context "as manager of an enterprise who sells 'any'" do
      before do
        user.enterprise_roles.create! enterprise: enterprise_any
      end

      it { expect(subject.can_manage_products?(user)).to be true }
      it { expect(subject.can_manage_enterprises?(user)).to be true }
      it { expect(subject.can_manage_orders?(user)).to be true }
      it { expect(subject.can_manage_order_cycles?(user)).to be true }
    end

    context "as manager of an enterprise who sell 'own'" do
      before do
        user.enterprise_roles.create! enterprise: enterprise_own
      end

      it { expect(subject.can_manage_products?(user)).to be true }
      it { expect(subject.can_manage_enterprises?(user)).to be true }
      it { expect(subject.can_manage_orders?(user)).to be true }
      it { expect(subject.can_manage_order_cycles?(user)).to be true }
    end

    context "as manager of an enterprise who sells 'none'" do
      before do
        user.enterprise_roles.create! enterprise: enterprise_none
      end

      it { expect(subject.can_manage_products?(user)).to be false }
      it { expect(subject.can_manage_enterprises?(user)).to be true }
      it { expect(subject.can_manage_orders?(user)).to be false }
      it { expect(subject.can_manage_order_cycles?(user)).to be false }
    end

    context "as manager of a producer enterprise who sells 'any'" do
      before do
        user.enterprise_roles.create! enterprise: enterprise_any_producer
      end

      it { expect(subject.can_manage_products?(user)).to be true }
      it { expect(subject.can_manage_enterprises?(user)).to be true }
      it { expect(subject.can_manage_orders?(user)).to be true }
      it { expect(subject.can_manage_order_cycles?(user)).to be true }
    end

    context "as manager of a producer enterprise who sell 'own'" do
      before do
        user.enterprise_roles.create! enterprise: enterprise_own_producer
      end

      it { expect(subject.can_manage_products?(user)).to be true }
      it { expect(subject.can_manage_enterprises?(user)).to be true }
      it { expect(subject.can_manage_orders?(user)).to be true }
      it { expect(subject.can_manage_order_cycles?(user)).to be true }
    end

    context "as manager of a producer enterprise who sells 'none'" do
      before do
        user.enterprise_roles.create! enterprise: enterprise_none_producer
      end

      context "as a non profile" do
        before do
          enterprise_none_producer.is_primary_producer = true
          enterprise_none_producer.producer_profile_only = false
          enterprise_none_producer.save!
        end

        it { expect(subject.can_manage_products?(user)).to be true }
        it { expect(subject.can_manage_enterprises?(user)).to be true }
        it { expect(subject.can_manage_orders?(user)).to be false }
        it { expect(subject.can_manage_order_cycles?(user)).to be false }
      end

      context "as a profile" do
        before do
          enterprise_none_producer.is_primary_producer = true
          enterprise_none_producer.producer_profile_only = true
          enterprise_none_producer.save!
        end

        it { expect(subject.can_manage_products?(user)).to be false }
        it { expect(subject.can_manage_enterprises?(user)).to be true }
        it { expect(subject.can_manage_orders?(user)).to be false }
        it { expect(subject.can_manage_order_cycles?(user)).to be false }
      end
    end

    context "as a new user with no enterprises" do
      it { expect(subject.can_manage_products?(user)).to be false }
      it { expect(subject.can_manage_enterprises?(user)).to be false }
      it { expect(subject.can_manage_orders?(user)).to be false }
      it { expect(subject.can_manage_order_cycles?(user)).to be false }

      it "can create enterprises straight off the bat" do
        expect(subject.is_new_user?(user)).to be true
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

    let(:p1) { create(:product, supplier: s1) }
    let(:p2) { create(:product, supplier: s2) }
    let(:p_related) { create(:product, supplier: s_related) }

    let(:er1) { create(:enterprise_relationship, parent: s1, child: d1) }
    let(:er2) { create(:enterprise_relationship, parent: d1, child: s1) }
    let(:er3) { create(:enterprise_relationship, parent: s2, child: d2) }

    let(:er_ps) {
      create(:enterprise_relationship, parent: s_related, child: s1,
                                       permissions_list: [:manage_products])
    }

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

      let(:order) { create(:order) }

      it "should be able to read/write their enterprises' products and variants" do
        is_expected.to have_ability([:admin, :read, :update, :bulk_update, :clone, :destroy],
                                    for: p1)
        is_expected.to have_ability(
          [:admin, :index, :read, :edit, :update, :search, :destroy,
           :delete], for: p1.variants.first
        )
      end

      it "should be able to read/write related enterprises' products " \
         "and variants with manage_products permission" do
        er_ps
        is_expected.to have_ability([:admin, :read, :update, :bulk_update, :clone, :destroy],
                                    for: p_related)
        is_expected.to have_ability(
          [:admin, :index, :read, :edit, :update, :search, :destroy,
           :delete], for: p_related.variants.first
        )
      end

      it "should not be able to read/write other enterprises' products and variants" do
        is_expected.not_to have_ability([:admin, :read, :update, :bulk_update, :clone, :destroy],
                                        for: p2)
        is_expected.not_to have_ability([:admin, :index, :read, :edit, :update, :search, :destroy],
                                        for: p2.variants.first)
      end

      it "should not be able to access admin actions on orders" do
        is_expected.not_to have_ability([:admin], for: Spree::Order)
      end

      it "should be able to create a new product" do
        is_expected.to have_ability(:create, for: Spree::Product)
      end

      it "should be able to read/write their enterprises' product variants" do
        is_expected.to have_ability([:create], for: Spree::Variant)
        is_expected.to have_ability(
          [:admin, :index, :read, :create, :edit, :search, :update, :destroy,
           :delete], for: p1.variants.first
        )
      end

      it "should not be able to read/write other enterprises' product variants" do
        is_expected.not_to have_ability(
          [:admin, :index, :read, :create, :edit, :search, :update,
           :destroy], for: p2.variants.first
        )
      end

      it "should be able to read/write their enterprises' product properties" do
        is_expected.to have_ability(
          [:admin, :index, :read, :create, :edit, :update_positions,
           :destroy], for: Spree::ProductProperty
        )
      end

      it "should be able to read/write their enterprises' product images" do
        is_expected.to have_ability([:admin, :index, :read, :create, :edit, :update, :destroy],
                                    for: Spree::Image)
      end

      it "should be able to read Taxons (in order to create classifications)" do
        is_expected.to have_ability([:admin, :index, :read, :search], for: Spree::Taxon)
      end

      it "should be able to read/write their enterprises' producer properties" do
        is_expected.to have_ability(
          [:admin, :index, :read, :create, :edit, :update_positions,
           :destroy], for: ProducerProperty
        )
      end

      it "should be able to read and create enterprise relationships" do
        is_expected.to have_ability([:admin, :index, :create], for: EnterpriseRelationship)
      end

      it "should be able to destroy enterprise relationships for its enterprises" do
        is_expected.to have_ability(:destroy, for: er1)
      end

      it "should be able to destroy enterprise relationships for other child-linked enterprises" do
        is_expected.to have_ability(:destroy, for: er2)
      end

      it "should not be able to destroy enterprise relationships for other enterprises" do
        is_expected.not_to have_ability(:destroy, for: er3)
      end

      it "should be able to read some reports" do
        is_expected.to have_ability(
          [:admin, :index, :show], for: Admin::ReportsController
        )
        is_expected.to have_ability(
          [:customers, :bulk_coop, :orders_and_fulfillment, :products_and_inventory,
           :order_cycle_management], for: :report
        )
      end

      include_examples "allows access to Enterprise Fee Summary"

      it "should not be able to read other reports" do
        is_expected.not_to have_ability(
          [:group_buys, :payments, :orders_and_distributors, :users_and_enterprises,
           :xero_invoices, :revenues_by_hub], for: :report
        )
      end

      it "should not be able to access customer actions" do
        is_expected.not_to have_ability([:admin, :index, :update], for: Customer)
      end

      describe "order_cycles abilities" do
        context "where the enterprise is not in an order_cycle" do
          let!(:order_cycle) { create(:simple_order_cycle) }

          it "should not be able to access read/update order_cycle actions" do
            is_expected.not_to have_ability([:admin, :index, :read, :edit, :update],
                                            for: order_cycle)
          end

          it "should not be able to access bulk_update, clone order cycle actions" do
            is_expected.not_to have_ability([:bulk_update, :clone], for: order_cycle)
          end

          it "cannot request permitted enterprises for an order cycle" do
            is_expected.not_to have_ability([:for_order_cycle], for: Enterprise)
          end

          it "cannot request permitted enterprise fees for an order cycle" do
            is_expected.not_to have_ability([:for_order_cycle], for: EnterpriseFee)
          end
        end

        context "where the enterprise is in an order_cycle" do
          let!(:order_cycle) { create(:simple_order_cycle) }
          let!(:exchange){
            create(:exchange, incoming: true, order_cycle: order_cycle,
                              receiver: order_cycle.coordinator, sender: s1)
          }

          it "should be able to access read/update order cycle actions" do
            is_expected.to have_ability([:admin, :index, :read, :edit, :update], for: order_cycle)
          end

          it "should not be able to access bulk/update, clone order cycle actions" do
            is_expected.not_to have_ability([:bulk_update, :clone], for: order_cycle)
          end

          it "can request permitted enterprises for an order cycle" do
            is_expected.to have_ability([:for_order_cycle], for: Enterprise)
          end

          it "can request permitted enterprise fees for an order cycle" do
            is_expected.to have_ability([:for_order_cycle], for: EnterpriseFee)
          end
        end
      end
    end

    context "when is a distributor enterprise user" do
      let(:user) do
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

      describe "editing enterprises" do
        let!(:d_related) { create(:distributor_enterprise) }
        let!(:er_pd) {
          create(:enterprise_relationship, parent: d_related, child: d1,
                                           permissions_list: [:edit_profile])
        }

        it "should be able to edit enterprises it manages" do
          is_expected.to have_ability(
            [:read, :edit, :update, :remove_logo, :remove_promo_image, :remove_terms_and_conditions,
             :bulk_update, :resend_confirmation], for: d1
          )
        end

        it "should be able to edit enterprises it has permission to" do
          is_expected.to have_ability(
            [:read, :edit, :update, :remove_logo, :remove_promo_image, :remove_terms_and_conditions,
             :bulk_update, :resend_confirmation], for: d_related
          )
        end

        it "should be able to manage shipping methods, payment methods and enterprise fees " \
           "for enterprises it manages" do
          is_expected.to have_ability(
            [:manage_shipping_methods, :manage_payment_methods, :manage_enterprise_fees], for: d1
          )
        end

        it "should not be able to manage shipping methods, payment methods and enterprise fees " \
           "for enterprises it has edit profile permission to" do
          is_expected.not_to have_ability(
            [:manage_shipping_methods, :manage_payment_methods,
             :manage_enterprise_fees], for: d_related
          )
        end
      end

      describe "variant overrides" do
        let(:vo1) { create(:variant_override, hub: d1, variant: p1.variants.first) }
        let(:vo2) { create(:variant_override, hub: d1, variant: p2.variants.first) }
        let(:vo3) { create(:variant_override, hub: d2, variant: p1.variants.first) }
        let(:vo4) { create(:variant_override, hub: d2, variant: p2.variants.first) }

        let!(:er1) {
          create(:enterprise_relationship, parent: s1, child: d1,
                                           permissions_list: [:create_variant_overrides])
        }

        it "should be able to access variant overrides page" do
          is_expected.to have_ability([:admin, :index, :bulk_update, :bulk_reset],
                                      for: VariantOverride)
        end

        it "should be able to read/write their own variant overrides" do
          is_expected.to have_ability([:admin, :index, :read, :update], for: vo1)
        end

        it "should not be able to read/write variant overrides " \
           "when producer of product hasn't granted permission" do
          is_expected.not_to have_ability([:admin, :index, :read, :update], for: vo2)
        end

        it "shouldn't be able to read/write variant overrides when we can't add hub to OC" do
          is_expected.not_to have_ability([:admin, :index, :read, :update], for: vo3)
        end

        it "should not be able to read/write other enterprises' variant overrides" do
          is_expected.not_to have_ability([:admin, :index, :read, :update], for: vo4)
        end
      end

      it "should be able to read/write their enterprises' orders" do
        is_expected.to have_ability([:admin, :index, :read, :edit], for: o1)
      end

      it "should not be able to read/write other enterprises' orders" do
        is_expected.not_to have_ability([:admin, :index, :read, :edit], for: o2)
      end

      it "should be able to read/write orders that are in the process of being created" do
        is_expected.to have_ability([:admin, :index, :read, :edit], for: o3)
      end

      it "should be able to create and search on nil (required for creating an order)" do
        is_expected.to have_ability([:create, :search], for: nil)
      end

      it "should be able to create a new order" do
        is_expected.to have_ability([:admin, :index, :read, :create, :update], for: Spree::Order)
      end

      it "should be able to create a new line item" do
        is_expected.to have_ability([:admin, :create], for: Spree::LineItem)
      end

      it "should be able to read/write Payments on a product" do
        is_expected.to have_ability([:admin, :index, :read, :create, :edit, :update, :fire],
                                    for: Spree::Payment)
      end

      it "should be able to read/write Shipments on a product" do
        is_expected.to have_ability([:admin, :index, :read, :create, :edit, :update, :fire],
                                    for: Spree::Shipment)
      end

      it "should be able to read/write Adjustments on a product" do
        is_expected.to have_ability([:admin, :index, :read, :create, :edit, :update, :fire],
                                    for: Spree::Adjustment)
      end

      it "should be able to read/write ReturnAuthorizations on a product" do
        is_expected.to have_ability([:admin, :index, :read, :create, :edit, :update, :fire],
                                    for: Spree::ReturnAuthorization)
      end

      it "should be able to read/write PaymentMethods" do
        is_expected.to have_ability([:admin, :index, :create, :update, :destroy],
                                    for: Spree::PaymentMethod)
      end

      it "should be able to read/write ShippingMethods" do
        is_expected.to have_ability([:admin, :index, :create, :update, :destroy],
                                    for: Spree::ShippingMethod)
      end

      it "should be able to read and create enterprise relationships" do
        is_expected.to have_ability([:admin, :index, :create], for: EnterpriseRelationship)
      end

      it "should be able to destroy enterprise relationships for its enterprises" do
        is_expected.to have_ability(:destroy, for: er2)
      end

      it "should be able to destroy enterprise relationships for other child-linked enterprises" do
        is_expected.to have_ability(:destroy, for: er1)
      end

      it "should not be able to destroy enterprise relationships for other enterprises" do
        is_expected.not_to have_ability(:destroy, for: er3)
      end

      it "should be able to read some reports" do
        is_expected.to have_ability(
          [:admin, :index, :show], for: Admin::ReportsController
        )
        is_expected.to have_ability(
          [:customers, :sales_tax, :group_buys, :bulk_coop, :payments,
           :orders_and_distributors, :orders_and_fulfillment, :products_and_inventory,
           :order_cycle_management, :xero_invoices], for: :report
        )
      end

      include_examples "allows access to Enterprise Fee Summary"

      it "should not be able to read other reports" do
        is_expected.not_to have_ability([:users_and_enterprises, :revenues_by_hub],
                                        for: :report)
      end

      it "should be able to access customer actions" do
        is_expected.to have_ability([:admin, :index, :update], for: Customer)
      end

      context "for a given order_cycle" do
        let!(:order_cycle) { create(:simple_order_cycle, coordinator: d2) }
        let!(:exchange){
          create(:exchange, incoming: false, order_cycle: order_cycle, receiver: d1,
                            sender: order_cycle.coordinator)
        }

        it "should be able to access read and update order cycle actions" do
          is_expected.to have_ability([:admin, :index, :read, :edit, :update], for: order_cycle)
        end

        it "should not be able to access bulk_update, clone order cycle actions" do
          is_expected.not_to have_ability([:bulk_update, :clone], for: order_cycle)
        end
      end

      it "can request permitted enterprises for an order cycle" do
        is_expected.to have_ability([:for_order_cycle], for: Enterprise)
      end

      it "can request permitted enterprise fees for an order cycle" do
        is_expected.to have_ability([:for_order_cycle], for: EnterpriseFee)
      end
    end

    context 'Order Cycle co-ordinator, distributor enterprise manager' do
      let(:user) do
        user = create(:user)
        user.spree_roles = []
        d1.enterprise_roles.build(user: user).save
        user
      end

      let(:oc1) { create(:simple_order_cycle, coordinator: d1) }
      let(:oc2) { create(:simple_order_cycle, coordinator: d2) }

      it "should be able to read/write OrderCycles they are the co-ordinator of" do
        is_expected.to have_ability(
          [:admin, :index, :read, :edit, :update, :bulk_update, :clone, :destroy], for: oc1
        )
      end

      it "should not be able to read/write OrderCycles they are not the co-ordinator of" do
        should_not have_ability(
          [:admin, :index, :read, :create, :edit, :update, :bulk_update, :clone, :destroy], for: oc2
        )
      end

      it "should be able to create OrderCycles" do
        is_expected.to have_ability([:create], for: OrderCycle)
      end

      it "should be able to read/write EnterpriseFees" do
        is_expected.to have_ability(
          [:admin, :index, :read, :create, :edit, :bulk_update, :destroy,
           :for_order_cycle], for: EnterpriseFee
        )
      end

      it "should be able to add enterprises to order cycles" do
        is_expected.to have_ability([:admin, :index, :for_order_cycle, :create], for: Enterprise)
      end
    end

    context 'enterprise manager' do
      let(:user) do
        user = create(:user)
        user.spree_roles = []
        s1.enterprise_roles.build(user: user).save
        user
      end

      it 'should have the ability to view the admin account page' do
        is_expected.to have_ability([:admin, :show], for: :account)
      end

      it 'should have the ability to read and edit enterprises that I manage' do
        is_expected.to have_ability([:read, :edit, :update, :bulk_update], for: s1)
      end

      it 'should not have the ability to read and edit enterprises that I do not manage' do
        is_expected.not_to have_ability([:read, :edit, :update, :bulk_update], for: s2)
      end

      it 'should not have the ability to welcome and register enterprises that I do not own' do
        is_expected.not_to have_ability([:welcome, :register], for: s1)
      end

      it 'should have the ability administrate and create enterpises' do
        is_expected.to have_ability([:admin, :index, :create], for: Enterprise)
      end

      it "should have the ability to search for users which share management of its enterprises" do
        is_expected.to have_ability([:admin, :known_users, :customers], for: :search)
        is_expected.not_to have_ability([:users], for: :search)
      end

      it "has the ability to manage vouchers" do
        is_expected.to have_ability([:admin, :create], for: Voucher)
      end
    end

    context 'enterprise owner' do
      let(:user) { s1.owner }

      it 'should have the ability to welcome and register enterprises that I own' do
        is_expected.to have_ability([:welcome, :register], for: s1)
      end

      it 'should have the ability to view the admin account page' do
        is_expected.to have_ability([:admin, :show], for: :account)
      end
    end
  end

  describe "permissions for variant overrides" do
    let!(:distributor) { create(:distributor_enterprise) }
    let!(:producer) { create(:supplier_enterprise) }
    let!(:product) { create(:product, supplier: producer) }
    let!(:variant) { create(:variant, product: product) }
    let!(:variant_override) { create(:variant_override, hub: distributor, variant: variant) }

    subject { user }

    let(:manage_actions) { [:admin, :index, :read, :update, :bulk_update, :bulk_reset] }

    describe "when admin" do
      before { user.spree_roles << Spree::Role.find_or_create_by!(name: 'admin') }

      it "should have permission" do
        is_expected.to have_ability(manage_actions, for: variant_override)
      end
    end

    describe "when user of the producer" do
      let(:user) { producer.owner }

      it "should not have permission" do
        is_expected.not_to have_ability(manage_actions, for: variant_override)
      end
    end

    describe "when user of the distributor" do
      let(:user) { distributor.owner }

      it "should not have permission" do
        is_expected.not_to have_ability(manage_actions, for: variant_override)
      end
    end

    describe "when user of the distributor which is also the producer" do
      let(:user) { distributor.owner }
      let!(:distributor) {
        create(:distributor_enterprise, is_primary_producer: true, sells: "any")
      }
      let!(:producer) { distributor }

      it "should have permission" do
        is_expected.to have_ability(manage_actions, for: variant_override)
      end
    end

    describe "when owner of the distributor with add_to_order_cycle permission to the producer" do
      let!(:unauthorized_enterprise) do
        create(:enterprise, sells: "any").tap do |record|
          create(:enterprise_relationship, parent: producer, child: record,
                                           permissions_list: [:add_to_order_cycle])
        end
      end
      let(:user) { unauthorized_enterprise.owner }

      it "should not have permission" do
        is_expected.not_to have_ability(manage_actions, for: variant_override)
      end
    end

    describe "when owner of enterprise with create_variant_overrides permission to the producer" do
      let!(:authorized_enterprise) do
        create(:enterprise, sells: "any").tap do |record|
          create(:enterprise_relationship, parent: producer, child: record,
                                           permissions_list: [:create_variant_overrides])
        end
      end
      let(:user) { authorized_enterprise.owner }

      it "should not have permission" do
        is_expected.not_to have_ability(manage_actions, for: variant_override)
      end

      describe "when the enterprise is not a distributor" do
        let!(:authorized_enterprise) do
          create(:enterprise, sells: "none").tap do |record|
            create(:enterprise_relationship, parent: producer, child: record,
                                             permissions_list: [:create_variant_overrides])
          end
        end

        it "should not have permission" do
          is_expected.not_to have_ability(manage_actions, for: variant_override)
        end
      end
    end
  end
end
