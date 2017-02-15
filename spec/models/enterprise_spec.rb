require 'spec_helper'

describe Enterprise do
  include AuthenticationWorkflow

  describe "sending emails" do
    describe "on creation" do
      let!(:user) { create_enterprise_user( enterprise_limit: 2 ) }
      let!(:enterprise) { create(:enterprise, owner: user) }

      context "when the email address has not already been confirmed" do
        it "sends a confirmation email" do
          expect do
            create(:enterprise, owner: user, email: "unknown@email.com", confirmed_at: nil )
          end.to enqueue_job Delayed::PerformableMethod
          Delayed::Job.last.payload_object.method_name.should == :send_on_create_confirmation_instructions_without_delay
        end

        it "does not send a welcome email" do
          expect(EnterpriseMailer).to_not receive(:welcome)
          create(:enterprise, owner: user, email: "unknown@email.com", confirmed_at: nil )
        end
      end

      context "when the email address has already been confirmed" do
        it "does not send a confirmation email" do
          expect(EnterpriseMailer).to_not receive(:confirmation_instructions)
          create(:enterprise, owner: user, email: enterprise.email, confirmed_at: nil)
        end

        it "sends a welcome email" do
          expect do
            create(:enterprise, owner: user, email: enterprise.email, confirmed_at: nil)
          end.to enqueue_job WelcomeEnterpriseJob
        end
      end
    end

    describe "on update of email" do
      let!(:user) { create_enterprise_user( enterprise_limit: 2 ) }
      let!(:enterprise) { create(:enterprise, owner: user) }

      it "when the email address has not already been confirmed" do
        expect do
          enterprise.update_attributes(email: "unknown@email.com")
        end.to enqueue_job Delayed::PerformableMethod
        Delayed::Job.last.payload_object.method_name.should == :send_confirmation_instructions_without_delay
      end

      it "when the email address has already been confirmed" do
        create(:enterprise, owner: user, email: "second.known.email@email.com") # Another enterpise with same owner but different email
        expect(EnterpriseMailer).to_not receive(:confirmation_instructions)
        enterprise.update_attributes!(email: "second.known.email@email.com")
      end
    end

    describe "on email confirmation" do
      let!(:user) { create_enterprise_user( enterprise_limit: 2 ) }
      let!(:unconfirmed_enterprise) { create(:enterprise, owner: user, confirmed_at: nil) }

      context "when we are confirming an email address for the first time for the enterprise" do
        it "sends a welcome email" do
          # unconfirmed_email is blank if we are not reconfirming an email
          unconfirmed_enterprise.unconfirmed_email = nil
          unconfirmed_enterprise.save!

          expect do
            unconfirmed_enterprise.confirm!
          end.to enqueue_job WelcomeEnterpriseJob, enterprise_id: unconfirmed_enterprise.id
        end
      end

      context "when we are reconfirming the email address for the enterprise" do
        it "does not send a welcome email" do
          # unconfirmed_email is present if we are reconfirming an email
          unconfirmed_enterprise.unconfirmed_email = "unconfirmed@email.com"
          unconfirmed_enterprise.save!

          expect(EnterpriseMailer).to_not receive(:welcome)
          unconfirmed_enterprise.confirm!
        end
      end
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

    it "destroys relationships upon destroy" do
      e = create(:enterprise)
      e_other = create(:enterprise)
      er1 = create(:enterprise_relationship, parent: e, child: e_other)
      er2 = create(:enterprise_relationship, child: e, parent: e_other)

      e.destroy

      EnterpriseRelationship.where(id: [er1, er2]).should be_empty
    end

    describe "relationships to other enterprises" do
      let(:e) { create(:distributor_enterprise) }
      let(:p) { create(:supplier_enterprise) }
      let(:c) { create(:distributor_enterprise) }

      let!(:er1) { create(:enterprise_relationship, parent_id: p.id, child_id: e.id) }
      let!(:er2) { create(:enterprise_relationship, parent_id: e.id, child_id: c.id) }

      it "finds relatives" do
        e.relatives.should match_array [p, c]
      end

      it "finds relatives_including_self" do
        expect(e.relatives_including_self).to include e
      end

      it "scopes relatives to visible distributors" do
        e.should_receive(:relatives_including_self).and_return(relatives = [])
        relatives.should_receive(:is_distributor).and_return relatives
        e.distributors
      end

      it "scopes relatives to visible producers" do
        e.should_receive(:relatives_including_self).and_return(relatives = [])
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
        }.to raise_error ActiveRecord::RecordInvalid, "Validation failed: #{u1.email} is not permitted to own any more enterprises (limit is 1)."
      end
    end
  end

  describe "validations" do
    subject { FactoryGirl.create(:distributor_enterprise) }
    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:permalink) }
    it { should ensure_length_of(:description).is_at_most(255) }

    it "requires an owner" do
      expect{
        e = create(:enterprise, owner: nil)
        }.to raise_error ActiveRecord::RecordInvalid, "Validation failed: Owner can't be blank"
    end

    describe "name uniqueness" do
      let(:owner) { create(:user, email: 'owner@example.com') }
      let!(:enterprise) { create(:enterprise, name: 'Enterprise', owner: owner) }

      it "prevents duplicate names for new records" do
        e = Enterprise.new name: enterprise.name
        e.should_not be_valid
        e.errors[:name].first.should ==
          "has already been taken. If this is your enterprise and you would like to claim ownership, please contact the current manager of this profile at owner@example.com."
      end

      it "prevents duplicate names for existing records" do
        e = create(:enterprise, name: 'foo')
        e.name = enterprise.name
        e.should_not be_valid
        e.errors[:name].first.should ==
          "has already been taken. If this is your enterprise and you would like to claim ownership, please contact the current manager of this profile at owner@example.com."
      end

      it "does not prohibit the saving of an enterprise with no name clash" do
        enterprise.should be_valid
      end

      it "takes the owner's email address as default email" do
        enterprise.email = nil
        enterprise.should be_valid
        enterprise.email.should be_present
        enterprise.email.should eq owner.email
      end
    end

    describe "preferred_shopfront_taxon_order" do
      it "empty strings are valid" do
        enterprise = build(:enterprise, preferred_shopfront_taxon_order: "")
        expect(enterprise).to be_valid
      end

      it "a single integer is valid" do
        enterprise = build(:enterprise, preferred_shopfront_taxon_order: "11")
        expect(enterprise).to be_valid
      end

      it "comma delimited integers are valid" do
        enterprise = build(:enterprise, preferred_shopfront_taxon_order: "1,2,3")
        expect(enterprise).to be_valid
        enterprise = build(:enterprise, preferred_shopfront_taxon_order: "1,22,333")
        expect(enterprise).to be_valid
      end

      it "commas at the beginning and end are disallowed" do
        enterprise = build(:enterprise, preferred_shopfront_taxon_order: ",1,2,3")
        expect(enterprise).to be_invalid
        enterprise = build(:enterprise, preferred_shopfront_taxon_order: "1,2,3,")
        expect(enterprise).to be_invalid
      end

      it "any other characters are invalid" do
        enterprise = build(:enterprise, preferred_shopfront_taxon_order: "a1,2,3")
        expect(enterprise).to be_invalid
        enterprise = build(:enterprise, preferred_shopfront_taxon_order: ".1,2,3")
        expect(enterprise).to be_invalid
        enterprise = build(:enterprise, preferred_shopfront_taxon_order: " 1,2,3")
        expect(enterprise).to be_invalid
      end
    end
  end

  describe "delegations" do
    #subject { FactoryGirl.create(:distributor_enterprise, :address => FactoryGirl.create(:address)) }

    it { should delegate(:latitude).to(:address) }
    it { should delegate(:longitude).to(:address) }
    it { should delegate(:city).to(:address) }
    it { should delegate(:state_name).to(:address) }
  end

  describe "callbacks" do
    it "restores permalink to original value when it is changed and invalid" do
      e1 = create(:enterprise, permalink: "taken")
      e2 = create(:enterprise, permalink: "not_taken")
      e2.permalink = "taken"
      e2.save
      expect(e2.permalink).to eq "not_taken"
    end
  end

  describe "scopes" do
    describe 'visible' do
      it 'find visible enterprises' do
        d1 = create(:distributor_enterprise, visible: false)
        s1 = create(:supplier_enterprise)
        Enterprise.visible.should == [s1]
      end
    end

    describe "confirmed" do
      it "find enterprises with a confirmed date" do
        s1 = create(:supplier_enterprise)
        d1 = create(:distributor_enterprise)
        s2 = create(:supplier_enterprise, confirmed_at: nil)
        d2 = create(:distributor_enterprise, confirmed_at: nil)
        expect(Enterprise.confirmed).to include s1, d1
        expect(Enterprise.confirmed).to_not include s2, d2
      end
    end

    describe "unconfirmed" do
      it "find enterprises without a confirmed date" do
        s1 = create(:supplier_enterprise)
        d1 = create(:distributor_enterprise)
        s2 = create(:supplier_enterprise, confirmed_at: nil)
        d2 = create(:distributor_enterprise, confirmed_at: nil)
        expect(Enterprise.unconfirmed).to_not include s1, d1
        expect(Enterprise.unconfirmed).to include s2, d2
      end
    end

    describe "activated" do
      let!(:inactive_enterprise1) { create(:enterprise, sells: "unspecified", confirmed_at: Time.zone.now) ;}
      let!(:inactive_enterprise2) { create(:enterprise, sells: "none", confirmed_at: nil) }
      let!(:active_enterprise) { create(:enterprise, sells: "none", confirmed_at: Time.zone.now) }

      it "finds enterprises that have a sells property other than 'unspecified' and that are confirmed" do
        activated_enterprises = Enterprise.activated
        expect(activated_enterprises).to include active_enterprise
        expect(activated_enterprises).to_not include inactive_enterprise1
        expect(activated_enterprises).to_not include inactive_enterprise2
      end
    end

    describe "ready_for_checkout" do
      let!(:e) { create(:enterprise) }

      it "does not show enterprises with no payment methods" do
        create(:shipping_method, distributors: [e])
        Enterprise.ready_for_checkout.should_not include e
      end

      it "does not show enterprises with no shipping methods" do
        create(:payment_method, distributors: [e])
        Enterprise.ready_for_checkout.should_not include e
      end

      it "does not show enterprises with unavailable payment methods" do
        create(:shipping_method, distributors: [e])
        create(:payment_method, distributors: [e], active: false)
        Enterprise.ready_for_checkout.should_not include e
      end

      it "shows enterprises with available payment and shipping methods" do
        create(:shipping_method, distributors: [e])
        create(:payment_method, distributors: [e])
        Enterprise.ready_for_checkout.should include e
      end
    end

    describe "not_ready_for_checkout" do
      let!(:e) { create(:enterprise) }

      it "shows enterprises with no payment methods" do
        create(:shipping_method, distributors: [e])
        Enterprise.not_ready_for_checkout.should include e
      end

      it "shows enterprises with no shipping methods" do
        create(:payment_method, distributors: [e])
        Enterprise.not_ready_for_checkout.should include e
      end

      it "shows enterprises with unavailable payment methods" do
        create(:shipping_method, distributors: [e])
        create(:payment_method, distributors: [e], active: false)
        Enterprise.not_ready_for_checkout.should include e
      end

      it "does not show enterprises with available payment and shipping methods" do
        create(:shipping_method, distributors: [e])
        create(:payment_method, distributors: [e])
        Enterprise.not_ready_for_checkout.should_not include e
      end
    end

    describe "#ready_for_checkout?" do
      let!(:e) { create(:enterprise) }

      it "returns false for enterprises with no payment methods" do
        create(:shipping_method, distributors: [e])
        e.reload.should_not be_ready_for_checkout
      end

      it "returns false for enterprises with no shipping methods" do
        create(:payment_method, distributors: [e])
        e.reload.should_not be_ready_for_checkout
      end

      it "returns false for enterprises with unavailable payment methods" do
        create(:shipping_method, distributors: [e])
        create(:payment_method, distributors: [e], active: false)
        e.reload.should_not be_ready_for_checkout
      end

      it "returns true for enterprises with available payment and shipping methods" do
        create(:shipping_method, distributors: [e])
        create(:payment_method, distributors: [e])
        e.reload.should be_ready_for_checkout
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
        create(:product, :distributors => [d], :deleted_at => Time.zone.now)
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

        Enterprise.with_distributed_active_products_on_hand.should match_array [d1, d2]
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

        Enterprise.with_distributed_active_products_on_hand.should match_array [d1, d2]
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

        Enterprise.with_supplied_active_products_on_hand.should match_array [d1, d2]
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

        Enterprise.supplying_variant_in([p1.master, p2.master]).should match_array [s1, s2]
      end

      it "does not return duplicates" do
        s = create(:supplier_enterprise)
        p1 = create(:simple_product, supplier: s)
        p2 = create(:simple_product, supplier: s)

        Enterprise.supplying_variant_in([p1.master, p2.master]).should == [s]
      end
    end

    describe "distributing_products" do
      it "returns enterprises distributing via a product distribution" do
        d = create(:distributor_enterprise)
        p = create(:product, distributors: [d])
        Enterprise.distributing_products(p).should == [d]
      end

      it "returns enterprises distributing via an order cycle" do
        d = create(:distributor_enterprise)
        p = create(:product)
        oc = create(:simple_order_cycle, distributors: [d], variants: [p.master])
        Enterprise.distributing_products(p).should == [d]
      end

      it "returns enterprises distributing via a product distribution" do
        d = create(:distributor_enterprise)
        p = create(:product, distributors: [d])
        Enterprise.distributing_products([p]).should == [d]
      end

      it "returns enterprises distributing via an order cycle" do
        d = create(:distributor_enterprise)
        p = create(:product)
        oc = create(:simple_order_cycle, distributors: [d], variants: [p.master])
        Enterprise.distributing_products([p]).should == [d]
      end

      it "does not return duplicate enterprises" do
        d = create(:distributor_enterprise)
        p1 = create(:product, distributors: [d])
        p2 = create(:product, distributors: [d])
        Enterprise.distributing_products([p1, p2]).should == [d]
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
  end

  describe "callbacks" do
    describe "after creation" do
      let(:owner) { create(:user, enterprise_limit: 10) }
      let(:hub1) { create(:distributor_enterprise, owner: owner) }
      let(:hub2) { create(:distributor_enterprise, owner: owner) }
      let(:hub3) { create(:distributor_enterprise, owner: owner) }
      let(:producer1) { create(:supplier_enterprise, owner: owner) }
      let(:producer2) { create(:supplier_enterprise, owner: owner) }

      describe "when a producer is created" do
        before do
          hub1
          hub2
        end

        it "creates links from the new producer to all hubs owned by the same user, granting add_to_order_cycle and create_variant_overrides permissions" do
          producer1

          should_have_enterprise_relationship from: producer1, to: hub1, with: [:add_to_order_cycle, :create_variant_overrides]
          should_have_enterprise_relationship from: producer1, to: hub2, with: [:add_to_order_cycle, :create_variant_overrides]
        end

        it "does not create any other links" do
          expect do
            producer1
          end.to change(EnterpriseRelationship, :count).by(2)
        end
      end


      describe "when a new hub is created" do
        it "it creates links to the hub, from all producers owned by the same user, granting add_to_order_cycle and create_variant_overrides permissions" do
          producer1
          producer2
          hub1

          should_have_enterprise_relationship from: producer1, to: hub1, with: [:add_to_order_cycle, :create_variant_overrides]
          should_have_enterprise_relationship from: producer2, to: hub1, with: [:add_to_order_cycle, :create_variant_overrides]
        end


        it "creates links from the new hub to all hubs owned by the same user, granting add_to_order_cycle permission" do
          hub1
          hub2
          hub3

          should_have_enterprise_relationship from: hub2, to: hub1, with: [:add_to_order_cycle]
          should_have_enterprise_relationship from: hub3, to: hub1, with: [:add_to_order_cycle]
          should_have_enterprise_relationship from: hub3, to: hub2, with: [:add_to_order_cycle]
        end

        it "does not create any other links" do
          producer1
          producer2
          expect { hub1 }.to change(EnterpriseRelationship, :count).by(2) # 2 producer links
          expect { hub2 }.to change(EnterpriseRelationship, :count).by(3) # 2 producer links + 1 hub link
          expect { hub3 }.to change(EnterpriseRelationship, :count).by(4) # 2 producer links + 2 hub links
        end
      end


      def should_have_enterprise_relationship(opts={})
        er = EnterpriseRelationship.where(parent_id: opts[:from], child_id: opts[:to]).last
        er.should_not be_nil
        if opts[:with] == :all_permissions
          er.permissions.map(&:name).should match_array ['add_to_order_cycle', 'manage_products', 'edit_profile', 'create_variant_overrides']
        elsif opts.key? :with
          er.permissions.map(&:name).should match_array opts[:with].map(&:to_s)
        end
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
    it "finds master and other variants" do
      d = create(:distributor_enterprise)
      p = create(:product, distributors: [d])
      v = p.variants.first
      d.distributed_variants.should match_array [p.master, v]
    end

    pending "finds variants distributed by order cycle" do
      # there isn't actually a method for this on Enterprise?
      d = create(:distributor_enterprise)
      p = create(:product)
      v = p.variants.first
      oc = create(:simple_order_cycle, distributors: [d], variants: [v])

      # This method doesn't do what this test says it does...
      d.distributed_variants.should match_array [v]
    end
  end

  describe "finding variants distributed by the enterprise in a product distribution only" do
    it "finds master and other variants" do
      d = create(:distributor_enterprise)
      p = create(:product, distributors: [d])
      v = p.variants.first
      d.product_distribution_variants.should match_array [p.master, v]
    end

    it "does not find variants distributed by order cycle" do
      d = create(:distributor_enterprise)
      p = create(:product)
      v = p.variants.first
      oc = create(:simple_order_cycle, distributors: [d], variants: [v])
      d.product_distribution_variants.should == []
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
      distributor.distributed_taxons.should match_array [taxon1, taxon2]
    end

    it "gets all taxons of all supplied products" do
      Spree::Product.stub(:in_supplier).and_return [product1, product2]
      supplier.supplied_taxons.should match_array [taxon1, taxon2]
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

  describe "provide enterprise category" do
    let(:producer_sell_all) { build(:enterprise, is_primary_producer: true,  sells: "any") }
    let(:producer_sell_own) { build(:enterprise, is_primary_producer: true,  sells: "own") }
    let(:producer_sell_none) { build(:enterprise, is_primary_producer: true,  sells: "none") }
    let(:non_producer_sell_all) { build(:enterprise, is_primary_producer: false,  sells: "any") }
    let(:non_producer_sell_own) { build(:enterprise, is_primary_producer: false,  sells: "own") }
    let(:non_producer_sell_none) { build(:enterprise, is_primary_producer: false, sells: "none") }

    it "should output enterprise categories" do
      producer_sell_all.is_primary_producer.should == true
      producer_sell_all.sells.should == "any"

      producer_sell_all.category.should == :producer_hub
      producer_sell_own.category.should == :producer_shop
      producer_sell_none.category.should == :producer
      non_producer_sell_all.category.should == :hub
      non_producer_sell_own.category.should == :hub
      non_producer_sell_none.category.should == :hub_profile
    end
  end

  describe "finding and automatically assigning a permalink" do
    let(:enterprise) { build(:enterprise, name: "Name To Turn Into A Permalink") }
    it "assigns permalink when initialized" do
      allow(Enterprise).to receive(:find_available_permalink).and_return("available_permalink")
      Enterprise.should_receive(:find_available_permalink).with("Name To Turn Into A Permalink")
      expect(
        lambda { enterprise.send(:initialize_permalink) }
      ).to change{
        enterprise.permalink
      }.to(
        "available_permalink"
      )
    end

    describe "finding a permalink" do
      let!(:enterprise1) { create(:enterprise, permalink: "permalink") }
      let!(:enterprise2) { create(:enterprise, permalink: "permalink1") }

      it "parameterizes the value provided" do
        expect(Enterprise.find_available_permalink("Some Unused Permalink")).to eq "some-unused-permalink"
      end

      it "sets the permalink to 'my-enterprise' if parametized permalink is blank" do
        expect(Enterprise.find_available_permalink("")).to eq "my-enterprise"
        expect(Enterprise.find_available_permalink("$$%{$**}$%}")).to eq "my-enterprise"
      end

      it "finds and index value based on existing permalinks" do
        expect(Enterprise.find_available_permalink("permalink")).to eq "permalink2"
      end

      it "ignores permalinks with characters after the index value" do
        create(:enterprise, permalink: "permalink2xxx")
        expect(Enterprise.find_available_permalink("permalink")).to eq "permalink2"
      end

      it "finds available permalink similar to existing" do
        create(:enterprise, permalink: "permalink2xxx")
        expect(Enterprise.find_available_permalink("permalink2")).to eq "permalink2"
      end

      it "finds gaps in the indices of existing permalinks" do
        create(:enterprise, permalink: "permalink3")
        expect(Enterprise.find_available_permalink("permalink")).to eq "permalink2"
      end
    end
  end
end
