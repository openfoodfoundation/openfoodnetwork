require 'spec_helper'

describe Enterprise do
  include AuthenticationWorkflow

  describe "creation" do
    it "should send a confirmation email" do
      mail_message = double "Mail::Message"
      EnterpriseMailer.should_receive(:confirmation_instructions).and_return mail_message
      mail_message.should_receive :deliver
      create(:enterprise)
    end
  end

  describe "associations" do
    it { should belong_to(:owner) }
    it { should have_many(:supplied_products) }
    it { should have_many(:distributed_orders) }
    it { should belong_to(:address) }
    it { should have_many(:product_distributions) }

    it "destroys enterprise roles upon its own demise" do
      e = create(:enterprise)
      u = create(:user)
      u.enterprise_roles.build(enterprise: e).save!

      role = e.enterprise_roles.first
      e.destroy
      EnterpriseRole.where(id: role.id).should be_empty
    end

    it "destroys supplied products upon destroy" do
      s = create(:supplier_enterprise)
      p = create(:simple_product, supplier: s)

      s.destroy

      Spree::Product.where(id: p.id).should be_empty
    end

    describe "relationships to other enterprises" do
      let(:e) { create(:distributor_enterprise) }
      let(:p) { create(:supplier_enterprise) }
      let(:c) { create(:distributor_enterprise) }

      let!(:er1) { create(:enterprise_relationship, parent_id: p.id, child_id: e.id) }
      let!(:er2) { create(:enterprise_relationship, parent_id: e.id, child_id: c.id) }

      it "finds relatives" do
        e.relatives.sort.should == [p, c].sort
      end

      it "scopes relatives to visible distributors" do
        e.should_receive(:relatives).and_return(relatives = [])
        relatives.should_receive(:is_distributor).and_return relatives
        e.distributors
      end

      it "scopes relatives to visible producers" do
        e.should_receive(:relatives).and_return(relatives = [])
        relatives.should_receive(:is_primary_producer).and_return relatives
        e.suppliers
      end
    end

    describe "ownership" do
      let(:u1) { create_enterprise_user }
      let(:u2) { create_enterprise_user }
      let!(:e) { create(:enterprise, owner: u1 ) }

      it "adds new owner to list of managers" do
        expect(e.owner).to eq u1
        expect(e.users).to include u1
        expect(e.users).to_not include u2
        e.owner = u2
        e.save!
        e.reload
        expect(e.owner).to eq u2
        expect(e.users).to include u1, u2
      end

      it "validates ownership limit" do
        expect(u1.enterprise_limit).to be 1
        expect(u1.owned_enterprises(:reload)).to eq [e]
        e2 = create(:enterprise, owner: u2 )
        expect{
          e2.owner = u1
          e2.save!
        }.to raise_error ActiveRecord::RecordInvalid, "Validation failed: You are not permitted to own own any more enterprises (limit is 1)."
      end
    end
  end

  describe "validations" do
    subject { FactoryGirl.create(:distributor_enterprise, :address => FactoryGirl.create(:address)) }
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:email) }

    it "requires an owner" do
      expect{
        e = create(:enterprise, owner: nil)
        }.to raise_error ActiveRecord::RecordInvalid, "Validation failed: Owner can't be blank"
    end
  end

  describe "delegations" do
    #subject { FactoryGirl.create(:distributor_enterprise, :address => FactoryGirl.create(:address)) }

    it { should delegate(:latitude).to(:address) }
    it { should delegate(:longitude).to(:address) }
    it { should delegate(:city).to(:address) }
    it { should delegate(:state_name).to(:address) }
  end
  describe "scopes" do
    describe 'active' do
      it 'find active enterprises' do
        d1 = create(:distributor_enterprise, visible: false)
        s1 = create(:supplier_enterprise)
        Enterprise.visible.should == [s1]
      end
    end

    describe "distributors_with_active_order_cycles" do
      it "finds active distributors by order cycles" do
        s = create(:supplier_enterprise)
        d = create(:distributor_enterprise)
        p = create(:product)
        create(:simple_order_cycle, suppliers: [s], distributors: [d], variants: [p.master])
        Enterprise.distributors_with_active_order_cycles.should == [d]
      end

      it "should not find inactive distributors by order cycles" do
        s = create(:supplier_enterprise)
        d = create(:distributor_enterprise)
        p = create(:product)
        create(:simple_order_cycle, :orders_open_at => 10.days.from_now, suppliers: [s], distributors: [d], variants: [p.master])
        Enterprise.distributors_with_active_order_cycles.should_not include d
      end
    end

    describe "active_distributors" do
      it "finds active distributors by product distributions" do
        d = create(:distributor_enterprise)
        create(:product, :distributors => [d])
        Enterprise.active_distributors.should == [d]
      end

      it "doesn't show distributors of deleted products" do
        d = create(:distributor_enterprise)
        create(:product, :distributors => [d], :deleted_at => Time.now)
        Enterprise.active_distributors.should be_empty
      end

      it "doesn't show distributors of unavailable products" do
        d = create(:distributor_enterprise)
        create(:product, :distributors => [d], :available_on => 1.week.from_now)
        Enterprise.active_distributors.should be_empty
      end

      it "doesn't show distributors of out of stock products" do
        d = create(:distributor_enterprise)
        create(:product, :distributors => [d], :on_hand => 0)
        Enterprise.active_distributors.should be_empty
      end

      it "finds active distributors by order cycles" do
        s = create(:supplier_enterprise)
        d = create(:distributor_enterprise)
        p = create(:product)
        create(:simple_order_cycle, suppliers: [s], distributors: [d], variants: [p.master])
        Enterprise.active_distributors.should == [d]
      end

      it "doesn't show distributors from inactive order cycles" do
        s = create(:supplier_enterprise)
        d = create(:distributor_enterprise)
        p = create(:product)
        create(:simple_order_cycle, suppliers: [s], distributors: [d], variants: [p.master], orders_open_at: 1.week.from_now, orders_close_at: 2.weeks.from_now)
        Enterprise.active_distributors.should be_empty
      end
    end

    describe "with_distributed_active_products_on_hand" do
      it "returns distributors with products in stock" do
        d1 = create(:distributor_enterprise)
        d2 = create(:distributor_enterprise)
        d3 = create(:distributor_enterprise)
        d4 = create(:distributor_enterprise)
        create(:product, :distributors => [d1, d2], :on_hand => 5)
        create(:product, :distributors => [d1], :on_hand => 5)
        create(:product, :distributors => [d3], :on_hand => 0)

        Enterprise.with_distributed_active_products_on_hand.sort.should == [d1, d2]
      end

      it "returns distributors with available products in stock" do
        d1 = create(:distributor_enterprise) # two products on hand
        d2 = create(:distributor_enterprise) # one product on hand
        d3 = create(:distributor_enterprise) # product on hand but not yet available
        d4 = create(:distributor_enterprise) # no products on hand
        d5 = create(:distributor_enterprise) # deleted product
        d6 = create(:distributor_enterprise) # no products
        create(:product, :distributors => [d1, d2], :on_hand => 5)
        create(:product, :distributors => [d1], :on_hand => 5)
        create(:product, :distributors => [d3], :on_hand => 5, :available_on => 1.week.from_now)
        create(:product, :distributors => [d4], :on_hand => 0)
        create(:product, :distributors => [d5]).delete

        Enterprise.with_distributed_active_products_on_hand.sort.should == [d1, d2]
        Enterprise.with_distributed_active_products_on_hand.distinct_count.should == 2
      end
    end

    describe "with_supplied_active_products_on_hand" do
      it "returns suppliers with available products in stock" do
        d1 = create(:supplier_enterprise) # two products on hand
        d2 = create(:supplier_enterprise) # one product on hand
        d3 = create(:supplier_enterprise) # product on hand but not yet available
        d4 = create(:supplier_enterprise) # no products on hand
        d5 = create(:supplier_enterprise) # deleted product
        d6 = create(:supplier_enterprise) # no products
        create(:product, :supplier => d1, :on_hand => 5)
        create(:product, :supplier => d1, :on_hand => 5)
        create(:product, :supplier => d2, :on_hand => 5)
        create(:product, :supplier => d3, :on_hand => 5, :available_on => 1.week.from_now)
        create(:product, :supplier => d4, :on_hand => 0)
        create(:product, :supplier => d5).delete

        Enterprise.with_supplied_active_products_on_hand.sort.should == [d1, d2]
        Enterprise.with_supplied_active_products_on_hand.distinct_count.should == 2
      end
    end

    describe "supplying_variant_in" do
      it "finds producers by supply of master variant" do
        s = create(:supplier_enterprise)
        p = create(:simple_product, supplier: s)

        Enterprise.supplying_variant_in([p.master]).should == [s]
      end

      it "finds producers by supply of variant" do
        s = create(:supplier_enterprise)
        p = create(:simple_product, supplier: s)
        v = create(:variant, product: p)

        Enterprise.supplying_variant_in([v]).should == [s]
      end

      it "returns multiple enterprises when given multiple variants" do
        s1 = create(:supplier_enterprise)
        s2 = create(:supplier_enterprise)
        p1 = create(:simple_product, supplier: s1)
        p2 = create(:simple_product, supplier: s2)

        Enterprise.supplying_variant_in([p1.master, p2.master]).sort.should == [s1, s2].sort
      end

      it "does not return duplicates" do
        s = create(:supplier_enterprise)
        p1 = create(:simple_product, supplier: s)
        p2 = create(:simple_product, supplier: s)

        Enterprise.supplying_variant_in([p1.master, p2.master]).should == [s]
      end
    end

    describe "distributing_product" do
      it "returns enterprises distributing via a product distribution" do
        d = create(:distributor_enterprise)
        p = create(:product, distributors: [d])
        Enterprise.distributing_product(p).should == [d]
      end

      it "returns enterprises distributing via an order cycle" do
        d = create(:distributor_enterprise)
        p = create(:product)
        oc = create(:simple_order_cycle, distributors: [d], variants: [p.master])
        Enterprise.distributing_product(p).should == [d]
      end
    end

    describe "distributing_any_product_of" do
      it "returns enterprises distributing via a product distribution" do
        d = create(:distributor_enterprise)
        p = create(:product, distributors: [d])
        Enterprise.distributing_any_product_of([p]).should == [d]
      end

      it "returns enterprises distributing via an order cycle" do
        d = create(:distributor_enterprise)
        p = create(:product)
        oc = create(:simple_order_cycle, distributors: [d], variants: [p.master])
        Enterprise.distributing_any_product_of([p]).should == [d]
      end

      it "does not return duplicate enterprises" do
        d = create(:distributor_enterprise)
        p1 = create(:product, distributors: [d])
        p2 = create(:product, distributors: [d])
        Enterprise.distributing_any_product_of([p1, p2]).should == [d]
      end
    end

    describe "managed_by" do
      it "shows only enterprises for given user" do
        user = create(:user)
        user.spree_roles = []
        e1 = create(:enterprise)
        e2 = create(:enterprise)
        e1.enterprise_roles.build(user: user).save

        enterprises = Enterprise.managed_by user
        enterprises.count.should == 1
        enterprises.should include e1
      end

      it "shows all enterprises for admin user" do
        user = create(:admin_user)
        e1 = create(:enterprise)
        e2 = create(:enterprise)

        enterprises = Enterprise.managed_by user
        enterprises.count.should == 2
        enterprises.should include e1
        enterprises.should include e2
      end
    end

    describe "accessible_by" do
      it "shows only enterprises that are invloved in order cycles which are common to those managed by the given user" do
        user = create(:user)
        user.spree_roles = []
        e1 = create(:enterprise)
        e2 = create(:enterprise)
        e3 = create(:enterprise)
        e4 = create(:enterprise)
        e1.enterprise_roles.build(user: user).save
        oc = create(:simple_order_cycle, coordinator: e2, suppliers: [e1], distributors: [e3])

        enterprises = Enterprise.accessible_by user
        enterprises.length.should == 3
        enterprises.should include e1, e2, e3
        enterprises.should_not include e4
      end

      it "shows all enterprises for admin user" do
        user = create(:admin_user)
        e1 = create(:enterprise)
        e2 = create(:enterprise)

        enterprises = Enterprise.managed_by user
        enterprises.length.should == 2
        enterprises.should include e1
        enterprises.should include e2
      end
    end
  end

  describe "has_supplied_products_on_hand?" do
    before :each do
      @supplier = create(:supplier_enterprise)
    end

    it "returns false when no products" do
      @supplier.should_not have_supplied_products_on_hand
    end

    it "returns false when the product is out of stock" do
      create(:product, :supplier => @supplier, :on_hand => 0)
      @supplier.should_not have_supplied_products_on_hand
    end

    it "returns true when the product is in stock" do
      create(:product, :supplier => @supplier, :on_hand => 1)
      @supplier.should have_supplied_products_on_hand
    end
  end

  describe "supplied_and_active_products_on_hand" do
    it "find only active products which are in stock" do
      supplier = create(:supplier_enterprise)
      inactive_product = create(:product, supplier:  supplier, on_hand: 1, available_on: Date.tomorrow)
      out_of_stock_product = create(:product, supplier:  supplier, on_hand: 0, available_on: Date.yesterday)
      p1 = create(:product, supplier: supplier, on_hand: 1, available_on: Date.yesterday)
      supplier.supplied_and_active_products_on_hand.should == [p1]
    end
  end

  describe "finding variants distributed by the enterprise" do
    it "finds the master variant" do
      d = create(:distributor_enterprise)
      p = create(:product, distributors: [d])
      d.distributed_variants.should == [p.master]
    end

    it "finds other variants" do
      d = create(:distributor_enterprise)
      p = create(:product, distributors: [d])
      v = create(:variant, product: p)
      d.distributed_variants.sort.should == [p.master, v].sort
    end

    it "finds variants distributed by order cycle" do
      d = create(:distributor_enterprise)
      p = create(:product)
      oc = create(:simple_order_cycle, distributors: [d], variants: [p.master])
      d.distributed_variants.should == [p.master]
    end
  end

  describe "finding variants distributed by the enterprise in a product distribution only" do
    it "finds the master variant" do
      d = create(:distributor_enterprise)
      p = create(:product, distributors: [d])
      d.product_distribution_variants.should == [p.master]
    end

    it "finds other variants" do
      d = create(:distributor_enterprise)
      p = create(:product, distributors: [d])
      v = create(:variant, product: p)
      d.product_distribution_variants.sort.should == [p.master, v].sort
    end

    it "does not find variants distributed by order cycle" do
      d = create(:distributor_enterprise)
      p = create(:product)
      oc = create(:simple_order_cycle, distributors: [d], variants: [p.master])
      d.product_distribution_variants.should == []
    end
  end

  describe "geo search" do
    before(:each) do
      Enterprise.delete_all

      state_id_vic = Spree::State.where(abbr: "Vic").first.id
      state_id_nsw = Spree::State.where(abbr: "NSW").first.id

      @suburb_in_vic = Suburb.create(name: "Camberwell", postcode: 3124, latitude: -37.824818, longitude: 145.057957, state_id: state_id_vic)
      @suburb_in_nsw = Suburb.create(name: "Cabramatta", postcode: 2166, latitude: -33.89507, longitude: 150.935889, state_id: state_id_nsw)

      address_vic1 = FactoryGirl.create(:address, state_id: state_id_vic, city: "Hawthorn", zipcode: "3123")
      address_vic1.update_column(:latitude, -37.842105)
      address_vic1.update_column(:longitude, 145.045951)

      address_vic2 = FactoryGirl.create(:address, state_id: state_id_vic, city: "Richmond", zipcode: "3121")
      address_vic2.update_column(:latitude, -37.826869)
      address_vic2.update_column(:longitude, 145.007098)

      FactoryGirl.create(:distributor_enterprise, address: address_vic1)
      FactoryGirl.create(:distributor_enterprise, address: address_vic2)
    end

    it "should find nearby hubs if there are any" do
      Enterprise.find_near(@suburb_in_vic).count.should eql(2)
    end

    it "should not have nils in the result" do
      Enterprise.find_near(@suburb_in_vic).should_not include(nil)
    end

    it "should not find hubs if not nearby " do
      Enterprise.find_near(@suburb_in_nsw).count.should eql(0)
    end
  end

  describe "taxons" do
    let(:distributor) { create(:distributor_enterprise) }
    let(:supplier) { create(:supplier_enterprise) }
    let(:taxon1) { create(:taxon) }
    let(:taxon2) { create(:taxon) }
    let(:product1) { create(:simple_product, primary_taxon: taxon1, taxons: [taxon1]) }
    let(:product2) { create(:simple_product, primary_taxon: taxon1, taxons: [taxon1, taxon2]) }

    it "gets all taxons of all distributed products" do
      Spree::Product.stub(:in_distributor).and_return [product1, product2]
      distributor.distributed_taxons.sort.should == [taxon1, taxon2].sort
    end

    it "gets all taxons of all supplied products" do
      Spree::Product.stub(:in_supplier).and_return [product1, product2]
      supplier.supplied_taxons.sort.should == [taxon1, taxon2].sort
    end
  end

  describe "presentation of attributes" do
    let(:distributor) {
      create(:distributor_enterprise,
             website: "http://www.google.com",
             facebook: "www.facebook.com/roger",
             linkedin: "https://linkedin.com")
    }

    it "strips http from url fields" do
      distributor.website.should == "www.google.com"
      distributor.facebook.should == "www.facebook.com/roger"
      distributor.linkedin.should == "linkedin.com"
    end
  end

  describe "producer properties" do
    let(:supplier) { create(:supplier_enterprise) }

    it "sets producer properties" do
      supplier.set_producer_property 'Organic Certified', 'NASAA 12345'

      supplier.producer_properties.count.should == 1
      supplier.producer_properties.first.value.should == 'NASAA 12345'
      supplier.producer_properties.first.property.presentation.should == 'Organic Certified'
    end
  end

  pending "provide enterprise category" do

    # Swap type values full > sell_all, single > sell_own profile > sell_none
    # swap is_distributor for new can_supply flag.
    let(:producer_sell_all_can_supply) {
      create(:enterprise, is_primary_producer: true,  type: "full",  is_distributor: true)
    }
    let(:producer_sell_all_cant_supply) {
      create(:enterprise, is_primary_producer: true,  type: "full",  is_distributor: false)
    }
    let(:producer_sell_own_can_supply) {
      create(:enterprise, is_primary_producer: true,  type: "single", is_distributor: true)
    }
    let(:producer_sell_own_cant_supply) {
      create(:enterprise, is_primary_producer: true,  type: "single", is_distributor: false)
    }
    let(:producer_sell_none_can_supply) {
      create(:enterprise, is_primary_producer: true,  type: "profile",  is_distributor: true)
    }
    let(:producer_sell_none_cant_supply) {
      create(:enterprise, is_primary_producer: true,  type: "profile",  is_distributor: false)
    }
    let(:non_producer_sell_all_can_supply) {
      create(:enterprise, is_primary_producer: true,  type: "full",  is_distributor: true)
    }
    let(:non_producer_sell_all_cant_supply) {
      create(:enterprise, is_primary_producer: true,  type: "full",  is_distributor: false)
    }
    let(:non_producer_sell_own_can_supply) {
      create(:enterprise, is_primary_producer: true,  type: "single", is_distributor: true)
    }
    let(:non_producer_sell_own_cant_supply) {
      create(:enterprise, is_primary_producer: true,  type: "single", is_distributor: false)
    }
    let(:non_producer_sell_none_can_supply) {
      create(:enterprise, is_primary_producer: false, type: "profile", is_distributor: true)
    }
    let(:non_producer_sell_none_cant_supply) {
      create(:enterprise, is_primary_producer: false, type: "profile", is_distributor: false)
    }

    it "should output enterprise categories" do
      producer_sell_all_can_supply.is_primary_producer.should == true
      producer_sell_all_can_supply.supplies.should == true
      producer_sell_all_can_supply.type.should == "full"

      producer_sell_all_can_supply.enterprise_category.should == "producer_hub"
      producer_sell_all_cant_supply.enterprise_category.should == "producer_hub"
      producer_sell_own_can_supply.enterprise_category.should == "producer_shop"
      producer_sell_own_cant_supply.enterprise_category.should == "producer_shop"
      producer_sell_none_can_supply.enterprise_category.should == "producer"
      producer_sell_none_cant_supply.enterprise_category.should == "producer_profile"
      non_producer_sell_all_can_supply.enterprise_category.should == "hub"
      non_producer_sell_all_cant_supply.enterprise_category.should == "hub"
      non_producer_sell_own_can_supply.enterprise_category.should == "hub"
      non_producer_sell_own_cant_supply.enterprise_category.should == "hub"
      non_producer_sell_none_can_supply.enterprise_category.should == "hub_profile"
      non_producer_sell_none_cant_supply.enterprise_category.should == "hub_profile"
    end
  end
end
