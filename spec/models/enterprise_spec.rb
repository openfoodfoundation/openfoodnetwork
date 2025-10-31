# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Enterprise do
  describe "sending emails" do
    describe "on creation" do
      let!(:user) { create(:user) }
      let!(:enterprise) { create(:enterprise, owner: user) }

      it "sends a welcome email" do
        expect do
          create(:enterprise, owner: user)
        end.to enqueue_job ActionMailer::MailDeliveryJob

        expect(enqueued_jobs.last.to_s).to match "welcome"
      end
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:owner).required }
    it { is_expected.to have_many(:supplied_products) }
    it { is_expected.to have_many(:supplied_variants) }
    it { is_expected.to have_many(:distributed_orders) }
    it { is_expected.to belong_to(:address).required }
    it { is_expected.to belong_to(:business_address).optional }
    it { is_expected.to have_many(:vouchers) }

    it "destroys enterprise roles upon its own demise" do
      e = create(:enterprise)
      u = create(:user)
      u.enterprise_roles.build(enterprise: e).save!

      role = e.enterprise_roles.first
      e.destroy
      expect(EnterpriseRole.where(id: role.id)).to be_empty
    end

    it "destroys supplied variants upon destroy" do
      pending "Variant are soft deletable, see: https://github.com/openfoodfoundation/openfoodnetwork/issues/2971"
      supplier = create(:supplier_enterprise)
      variant = create(:variant, supplier:)

      supplier.destroy

      expect(Spree::Variant.where(id: variant.id)).to be_empty
    end

    it "destroys relationships upon destroy" do
      e = create(:enterprise)
      e_other = create(:enterprise)
      er1 = create(:enterprise_relationship, parent: e, child: e_other)
      er2 = create(:enterprise_relationship, child: e, parent: e_other)

      e.destroy

      expect(EnterpriseRelationship.where(id: [er1, er2])).to be_empty
    end

    it "does not destroy distributed_orders upon destroy" do
      enterprise = create(:distributor_enterprise)
      create_list(:order, 2, distributor: enterprise)

      expect do
        enterprise.destroy
        expect(enterprise.errors.full_messages).to eq(
          ["Cannot delete record because dependent distributed orders exist"]
        )
      end.to change { Spree::Order.count }.by(0)
    end

    it "does not destroy distributor_payment_methods upon destroy" do
      enterprise = create(:distributor_enterprise)
      create_list(:distributor_payment_method, 2, distributor: enterprise)

      expect do
        enterprise.destroy
        expect(enterprise.errors.full_messages).to eq(
          ["Cannot delete record because dependent distributor payment methods exist"]
        )
      end.to change { Spree::Order.count }.by(0)
    end

    it "does not destroy distributor_shipping_methods upon destroy" do
      enterprise = create(:distributor_enterprise)
      create_list(:distributor_shipping_method, 2, distributor: enterprise)

      expect do
        enterprise.destroy
        expect(enterprise.errors.full_messages).to eq(
          ["Cannot delete record because dependent distributor shipping methods exist"]
        )
      end.to change { Spree::Order.count }.by(0)
    end

    it "does not destroy enterprise_fees upon destroy" do
      enterprise = create(:enterprise)
      create_list(:enterprise_fee, 2, enterprise:)

      expect do
        enterprise.destroy
        expect(enterprise.errors.full_messages).to eq(
          ["Cannot delete record because dependent enterprise fees exist"]
        )
      end.to change { Spree::Order.count }.by(0)
    end

    it "does not destroy vouchers upon destroy" do
      enterprise = create(:enterprise)
      (1..2).map do |code|
        create(:voucher, enterprise:, code: "new code #{code}")
      end

      expect do
        enterprise.destroy
        expect(enterprise.errors.full_messages).to eq(
          ["Cannot delete record because dependent vouchers exist"]
        )
      end.to change { Spree::Order.count }.by(0)
    end

    describe "relationships to other enterprises" do
      let(:e) { create(:distributor_enterprise) }
      let(:p) { create(:supplier_enterprise) }
      let(:c) { create(:distributor_enterprise) }

      let!(:er1) { create(:enterprise_relationship, parent_id: p.id, child_id: e.id) }
      let!(:er2) { create(:enterprise_relationship, parent_id: e.id, child_id: c.id) }

      it "finds relatives" do
        expect(e.relatives).to match_array [p, c]
      end

      it "finds relatives_including_self" do
        expect(e.relatives_including_self).to include e
      end

      it "scopes relatives to visible distributors" do
        enterprise = build_stubbed(:distributor_enterprise)
        expect(enterprise).to receive(:relatives_including_self).and_return(relatives = [])
        expect(relatives).to receive(:is_distributor).and_return relatives
        enterprise.distributors
      end

      it "scopes relatives to visible producers" do
        enterprise = build_stubbed(:distributor_enterprise)
        expect(enterprise).to receive(:relatives_including_self).and_return(relatives = [])
        expect(relatives).to receive(:is_primary_producer).and_return relatives
        enterprise.suppliers
      end
    end

    describe "ownership" do
      let(:u1) { create(:user) }
      let(:u2) { create(:user) }
      let!(:e) { create(:enterprise, owner: u1 ) }

      it "adds new owner to list of managers" do
        expect(e.owner).to eq u1
        expect(e.users).to include u1
        expect(e.users).not_to include u2
        e.owner = u2
        e.save!
        e.reload
        expect(e.owner).to eq u2
        expect(e.users).to include u1, u2
      end

      it "validates ownership limit" do
        expect(u1.enterprise_limit).to be 5
        expect(u1.owned_enterprises.reload).to eq [e]
        4.times { create(:enterprise, owner: u1) }
        e2 = create(:enterprise, owner: u2)
        expect {
          e2.owner = u1
          e2.save!
        }.to raise_error ActiveRecord::RecordInvalid,
                         "Validation failed: #{u1.email} is not permitted " \
                         "to own any more enterprises (limit is 5)."
      end
    end
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it do
      create(:distributor_enterprise)
      is_expected.to validate_uniqueness_of(:permalink)
    end

    describe "name uniqueness" do
      let(:owner) { create(:user, email: 'owner@example.com') }
      let!(:enterprise) { create(:enterprise, name: 'Enterprise', owner:) }

      it "prevents duplicate names for new records" do
        e = Enterprise.new name: enterprise.name
        expect(e).not_to be_valid
        expect(e.errors[:name].first).to include enterprise_name_error(owner.email)
      end

      it "prevents duplicate names for existing records" do
        e = create(:enterprise, name: 'foo')
        e.name = enterprise.name
        expect(e).not_to be_valid
        expect(e.errors[:name].first).to include enterprise_name_error(owner.email)
      end

      it "does not prohibit the saving of an enterprise with no name clash" do
        expect(enterprise).to be_valid
      end

      it "sets the enterprise contact to the owner by default" do
        expect(enterprise.contact).to eq enterprise.owner
      end
    end

    describe "prevent a wrong instagram link pattern" do
      it "invalidates the instagram attribute https://facebook.com/user" do
        e = build(:enterprise, instagram: 'https://facebook.com/user')
        expect(e).not_to be_valid
      end

      it "invalidates the instagram attribute tagram.com/user" do
        e = build(:enterprise, instagram: 'tagram.com/user')
        expect(e).not_to be_valid
      end

      it "invalidates the instagram attribute https://instagram.com/user/preferences" do
        e = build(:enterprise, instagram: 'https://instagram.com/user/preferences')
        expect(e).not_to be_valid
      end

      it "invalidates the instagram attribute https://www.instagram.com/p/Cpg4McNPyJA/" do
        e = build(:enterprise, instagram: 'https://www.instagram.com/p/Cpg4McNPyJA/')
        expect(e).not_to be_valid
      end

      it "invalidates the instagram attribute https://instagram.com/user-user" do
        e = build(:enterprise, instagram: 'https://instagram.com/user-user')
        expect(e).not_to be_valid
      end
    end

    describe "Verify accepted instagram url pattern" do
      it "validates empty instagram attribute" do
        e = build(:enterprise, instagram: '')
        expect(e).to be_valid
        expect(e.instagram).to eq ""
      end

      it "validates the instagram attribute @my_user" do
        e = build(:enterprise, instagram: '@my_user')
        expect(e).to be_valid
        expect(e.instagram).to eq "my_user"
      end

      it "validates the instagram attribute user" do
        e = build(:enterprise, instagram: 'user')
        expect(e).to be_valid
        expect(e.instagram).to eq "user"
      end

      it "validates the instagram attribute my_www5.example" do
        e = build(:enterprise, instagram: 'my_www5.example')
        expect(e).to be_valid
        expect(e.instagram).to eq "my_www5.example"
      end

      it "validates the instagram attribute http://instagram.com/user" do
        e = build(:enterprise, instagram: 'http://instagram.com/user')
        expect(e).to be_valid
        expect(e.instagram).to eq "user"
      end

      it "validates the instagram attribute https://www.instagram.com/user" do
        e = build(:enterprise, instagram: 'https://www.instagram.com/user')
        expect(e).to be_valid
        expect(e.instagram).to eq "user"
      end

      it "validates the instagram attribute instagram.com/@user" do
        e = build(:enterprise, instagram: 'instagram.com/@user')
        expect(e).to be_valid
        expect(e.instagram).to eq "user"
      end

      it "validates the instagram attribute Https://www.Instagram.com/@User" do
        e = build(:enterprise, instagram: 'Https://www.Instagram.com/@User')
        expect(e).to be_valid
        expect(e.instagram).to eq "user"
      end

      it "validates the instagram attribute instagram.com/user" do
        e = build(:enterprise, instagram: 'instagram.com/user')
        expect(e).to be_valid
        expect(e.instagram).to eq "user"
      end

      it "renders the expected pattern" do
        e = build(:enterprise, instagram: 'instagram.com/user')
        expect(e.instagram).to eq "user"
      end
    end

    describe "preferred_shopfront_message" do
      it "sanitises HTML" do
        enterprise = build(:enterprise, preferred_shopfront_message:
                           'Hello <script>alert</script> dearest <b>monster</b>.')
        expect(enterprise.preferred_shopfront_message)
          .to eq "Hello alert dearest <b>monster</b>."
      end
    end

    describe "preferred_shopfront_closed_message" do
      it "sanitises HTML" do
        enterprise = build(:enterprise, preferred_shopfront_closed_message:
                           'Hello <script>alert</script> dearest <b>monster</b>.')
        expect(enterprise.preferred_shopfront_closed_message)
          .to eq "Hello alert dearest <b>monster</b>."
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
        expect(enterprise).not_to be_valid
        enterprise = build(:enterprise, preferred_shopfront_taxon_order: "1,2,3,")
        expect(enterprise).not_to be_valid
      end

      it "any other characters are invalid" do
        enterprise = build(:enterprise, preferred_shopfront_taxon_order: "a1,2,3")
        expect(enterprise).not_to be_valid
        enterprise = build(:enterprise, preferred_shopfront_taxon_order: ".1,2,3")
        expect(enterprise).not_to be_valid
        enterprise = build(:enterprise, preferred_shopfront_taxon_order: " 1,2,3")
        expect(enterprise).not_to be_valid
      end
    end

    describe "preferred_shopfront_producer_order" do
      it "empty strings are valid" do
        enterprise = build(:enterprise, preferred_shopfront_producer_order: "")
        expect(enterprise).to be_valid
      end

      it "a single integer is valid" do
        enterprise = build(:enterprise, preferred_shopfront_producer_order: "11")
        expect(enterprise).to be_valid
      end

      it "comma delimited integers are valid" do
        enterprise = build(:enterprise, preferred_shopfront_producer_order: "1,2,3")
        expect(enterprise).to be_valid
        enterprise = build(:enterprise, preferred_shopfront_producer_order: "1,22,333")
        expect(enterprise).to be_valid
      end

      it "commas at the beginning and end are disallowed" do
        enterprise = build(:enterprise, preferred_shopfront_producer_order: ",1,2,3")
        expect(enterprise).not_to be_valid
        enterprise = build(:enterprise, preferred_shopfront_producer_order: "1,2,3,")
        expect(enterprise).not_to be_valid
      end

      it "any other characters are invalid" do
        enterprise = build(:enterprise, preferred_shopfront_producer_order: "a1,2,3")
        expect(enterprise).not_to be_valid
        enterprise = build(:enterprise, preferred_shopfront_producer_order: ".1,2,3")
        expect(enterprise).not_to be_valid
        enterprise = build(:enterprise, preferred_shopfront_producer_order: " 1,2,3")
        expect(enterprise).not_to be_valid
      end
    end

    describe "white label logo link" do
      before do
        # validate white_label_logo_link only if white_label_logo is present
        allow_any_instance_of(Enterprise).to receive(:white_label_logo).and_return(true)
      end

      it "validates the white_label_logo_link attribute" do
        e = build(:enterprise, white_label_logo_link: 'http://www.example.com')
        expect(e).to be_valid
        expect(e.white_label_logo_link).to eq "http://www.example.com"
      end

      it "adds http:// to the white_label_logo_link attribute if it is missing" do
        e = build(:enterprise, white_label_logo_link: 'www.example.com')
        expect(e).to be_valid
        expect(e.white_label_logo_link).to eq "http://www.example.com"
      end

      it "ignores whitespace around the URL form copying and pasting" do
        e = build(:enterprise, white_label_logo_link: ' www.example.com ')
        expect(e).to be_valid
        expect(e.white_label_logo_link).to eq "http://www.example.com"
      end

      it "does not validate if URL is invalid and can't be infered" do
        e = build(:enterprise, white_label_logo_link: 'with spaces')
        expect(e).not_to be_valid
      end
    end

    describe "external_billing_id" do
      it "validates the external_billing_id attribute" do
        e = build(:enterprise, external_billing_id: '123456')
        expect(e).to be_valid
      end

      it "does not validate the external_billing_id attribute with spaces" do
        e = build(:enterprise, external_billing_id: '123 456')
        expect(e).not_to be_valid
      end
    end
  end

  describe "serialisation" do
    it "sanitises HTML in long_description" do
      subject.long_description = "Hello <script>alert</script> dearest <b>monster</b>."
      expect(subject.long_description).to eq "Hello alert dearest <b>monster</b>."
    end
  end

  describe "callbacks" do
    describe "restore_permalink" do
      it "restores permalink to original value when it is changed and invalid" do
        e1 = create(:enterprise, permalink: "taken")
        e2 = create(:enterprise, permalink: "not_taken")
        e2.permalink = "taken"
        e2.save
        expect(e2.reload.permalink).to eq "not_taken"
      end
    end

    describe "touch_distributors" do
      it "touches supplied variant distributors" do
        enterprise = create(:enterprise)
        variant = create(:variant)
        enterprise.supplied_variants << variant

        updated_at = 1.hour.ago
        distributor1 = create(:distributor_enterprise, updated_at:)
        distributor2 = create(:distributor_enterprise, updated_at:)

        create(:simple_order_cycle, distributors: [distributor1], variants: [variant])
        create(:simple_order_cycle, distributors: [distributor2], variants: [variant])

        expect { enterprise.touch }
          .to change { distributor1.reload.updated_at }
          .and change { distributor2.reload.updated_at }
      end
    end
  end

  describe "scopes" do
    describe 'visible' do
      it 'find visible enterprises' do
        d1 = create(:distributor_enterprise, visible: false)
        s1 = create(:supplier_enterprise)
        expect(Enterprise.visible).to eq([s1])
      end
    end

    describe "activated" do
      let!(:unconfirmed_user) { create(:user, confirmed_at: nil, enterprise_limit: 2) }
      let!(:inactive_enterprise) { create(:enterprise, sells: "unspecified") }
      let!(:active_enterprise) { create(:enterprise, sells: "none") }

      it "finds enterprises that have a sells property other than 'unspecified'" do
        activated_enterprises = Enterprise.activated
        expect(activated_enterprises).to include active_enterprise
        expect(activated_enterprises).not_to include inactive_enterprise
      end
    end

    describe "ready_for_checkout" do
      let!(:e) { create(:enterprise) }

      it "does not show enterprises with no payment methods" do
        create(:shipping_method, distributors: [e])
        expect(Enterprise.ready_for_checkout).not_to include e
      end

      it "does not show enterprises with no shipping methods" do
        create(:payment_method, distributors: [e])
        expect(Enterprise.ready_for_checkout).not_to include e
      end

      it "does not show enterprises with unavailable payment methods" do
        create(:shipping_method, distributors: [e])
        create(:payment_method, distributors: [e], active: false)
        expect(Enterprise.ready_for_checkout).not_to include e
      end

      it "does not show enterprises which only have backend shipping methods" do
        create(:shipping_method, distributors: [e],
                                 display_on: Spree::ShippingMethod::DISPLAY_ON_OPTIONS[:back_end])
        create(:payment_method, distributors: [e])
        expect(Enterprise.ready_for_checkout).not_to include e
      end

      it "shows enterprises with available payment and shipping methods" do
        create(:shipping_method, distributors: [e])
        create(:payment_method, distributors: [e])
        expect(Enterprise.ready_for_checkout).to include e
      end
    end

    describe "not_ready_for_checkout" do
      let!(:e) { create(:enterprise) }

      it "shows enterprises with no payment methods" do
        create(:shipping_method, distributors: [e])
        expect(Enterprise.not_ready_for_checkout).to include e
      end

      it "shows enterprises with no shipping methods" do
        create(:payment_method, distributors: [e])
        expect(Enterprise.not_ready_for_checkout).to include e
      end

      it "shows enterprises with unavailable payment methods" do
        create(:shipping_method, distributors: [e])
        create(:payment_method, distributors: [e], active: false)
        expect(Enterprise.not_ready_for_checkout).to include e
      end

      it "shows enterprises which only have backend shipping methods" do
        create(:shipping_method, distributors: [e],
                                 display_on: Spree::ShippingMethod::DISPLAY_ON_OPTIONS[:back_end])
        create(:payment_method, distributors: [e])
        expect(Enterprise.not_ready_for_checkout).to include e
      end

      it "does not show enterprises with available payment and shipping methods" do
        create(:shipping_method, distributors: [e])
        create(:payment_method, distributors: [e])
        expect(Enterprise.not_ready_for_checkout).not_to include e
      end
    end

    describe "#ready_for_checkout?" do
      let!(:e) { create(:enterprise) }

      it "returns false for enterprises with no payment methods" do
        create(:shipping_method, distributors: [e])
        expect(e.reload).not_to be_ready_for_checkout
      end

      it "returns false for enterprises with no shipping methods" do
        create(:payment_method, distributors: [e])
        expect(e.reload).not_to be_ready_for_checkout
      end

      it "returns false for enterprises with unavailable payment methods" do
        create(:shipping_method, distributors: [e])
        create(:payment_method, distributors: [e], active: false)
        expect(e.reload).not_to be_ready_for_checkout
      end

      it "returns false for enterprises which only have backend shipping methods" do
        create(:shipping_method, distributors: [e],
                                 display_on: Spree::ShippingMethod::DISPLAY_ON_OPTIONS[:back_end])
        create(:payment_method, distributors: [e])
        expect(e.reload).not_to be_ready_for_checkout
      end

      it "returns true for enterprises with available payment and shipping methods" do
        create(:shipping_method, distributors: [e])
        create(:payment_method, distributors: [e])
        expect(e.reload).to be_ready_for_checkout
      end

      it "returns false for enterprises with payment methods that are available but not configured
          correctly" do
        create(:shipping_method, distributors: [e])
        create(:stripe_sca_payment_method, distributors: [e])
        expect(e.reload).not_to be_ready_for_checkout
      end
    end

    describe "distributors_with_active_order_cycles" do
      it "finds active distributors by order cycles" do
        s = create(:supplier_enterprise)
        d = create(:distributor_enterprise)
        p = create(:product)
        create(:simple_order_cycle, suppliers: [s], distributors: [d], variants: [p.variants.first])
        expect(Enterprise.distributors_with_active_order_cycles).to eq([d])
      end

      it "should not find inactive distributors by order cycles" do
        s = create(:supplier_enterprise)
        d = create(:distributor_enterprise)
        p = create(:product)
        create(:simple_order_cycle, orders_open_at: 10.days.from_now,
                                    orders_close_at: 17.days.from_now, suppliers: [s],
                                    distributors: [d], variants: [p.variants.first])
        expect(Enterprise.distributors_with_active_order_cycles).not_to include d
      end
    end

    describe ".supplying_variant_in" do
      it "finds producers by supply of variant" do
        supplier = create(:supplier_enterprise)
        variant = create(:variant, supplier:)

        expect(Enterprise.supplying_variant_in([variant])).to eq([supplier])
      end

      it "returns multiple enterprises when given multiple variants" do
        supplier1 = create(:supplier_enterprise)
        supplier2 = create(:supplier_enterprise)
        variant1 = create(:variant, supplier: supplier1)
        variant2 = create(:variant, supplier: supplier2)

        expect(Enterprise.supplying_variant_in([variant1, variant2]))
          .to match_array([supplier1, supplier2])
      end

      it "does not return duplicates" do
        supplier = create(:supplier_enterprise)
        variant1 = create(:variant, supplier:)
        variant2 = create(:variant, supplier:)

        expect(Enterprise.supplying_variant_in([variant1, variant2])).to eq([supplier])
      end
    end

    describe "distributing_variants" do
      let(:distributor) { create(:distributor_enterprise) }
      let(:variant) { create(:variant) }

      it "returns enterprises distributing via an order cycle" do
        order_cycle = create(:simple_order_cycle, distributors: [distributor], variants: [variant])
        expect(Enterprise.distributing_variants(variant.id)).to eq([distributor])
      end

      it "does not return duplicate enterprises" do
        another_variant = create(:variant)
        order_cycle = create(:simple_order_cycle, distributors: [distributor],
                                                  variants: [variant, another_variant])
        expect(Enterprise.distributing_variants(
                 [variant.id, another_variant.id]
               )).to eq([distributor])
      end
    end

    describe "managed_by" do
      it "shows only enterprises for given user" do
        user = create(:user)
        e1 = create(:enterprise)
        e2 = create(:enterprise)
        e1.enterprise_roles.build(user:).save

        enterprises = Enterprise.managed_by user
        expect(enterprises.count).to eq(1)
        expect(enterprises).to include e1
      end

      it "shows all enterprises for admin user" do
        user = create(:admin_user)
        e1 = create(:enterprise)
        e2 = create(:enterprise)

        enterprises = Enterprise.managed_by user
        expect(enterprises.count).to eq(2)
        expect(enterprises).to include e1
        expect(enterprises).to include e2
      end
    end
  end

  describe "callbacks" do
    describe "after creation" do
      let(:owner) { create(:user, enterprise_limit: 10) }
      let(:hub1) { create(:distributor_enterprise, owner:) }
      let(:hub2) { create(:distributor_enterprise, owner:) }
      let(:hub3) { create(:distributor_enterprise, owner:) }
      let(:producer1) { create(:supplier_enterprise, owner:) }
      let(:producer2) { create(:supplier_enterprise, owner:) }

      describe "when a producer is created" do
        before do
          hub1
          hub2
        end

        it "creates links from the new producer to all hubs owned by the same user, " \
           "granting add_to_order_cycle and create_variant_overrides permissions" do
          producer1

          should_have_enterprise_relationship from: producer1, to: hub1,
                                              with: [:add_to_order_cycle, :create_variant_overrides]
          should_have_enterprise_relationship from: producer1, to: hub2,
                                              with: [:add_to_order_cycle, :create_variant_overrides]
        end

        it "does not create any other links" do
          expect do
            producer1
          end.to change { EnterpriseRelationship.count }.by(2)
        end
      end

      describe "when a new hub is created" do
        it "it creates links to the hub, from all producers owned by the same user, " \
           "granting add_to_order_cycle and create_variant_overrides permissions" do
          producer1
          producer2
          hub1

          should_have_enterprise_relationship from: producer1, to: hub1,
                                              with: [:add_to_order_cycle, :create_variant_overrides]
          should_have_enterprise_relationship from: producer2, to: hub1,
                                              with: [:add_to_order_cycle, :create_variant_overrides]
        end

        it "creates links from the new hub to all hubs owned by the same user, " \
           "granting add_to_order_cycle permission" do
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
          expect { hub1 }.to change { EnterpriseRelationship.count }.by(2) # 2 producer links
          expect {
            hub2
          }.to change { EnterpriseRelationship.count }.by(3) # 2 producer links + 1 hub link
          expect {
            hub3
          }.to change { EnterpriseRelationship.count }.by(4) # 2 producer links + 2 hub links
        end
      end

      def should_have_enterprise_relationship(opts = {})
        er = EnterpriseRelationship.where(parent_id: opts[:from], child_id: opts[:to]).last
        expect(er).not_to be_nil
        if opts[:with] == :all_permissions
          expect(er.permissions.map(&:name)).to match_array ['add_to_order_cycle',
                                                             'manage_products', 'edit_profile',
                                                             'create_variant_overrides']
        elsif opts.key? :with
          expect(er.permissions.map(&:name)).to match_array opts[:with].map(&:to_s)
        end
      end
    end
  end

  describe "finding variants distributed by the enterprise" do
    it "finds variants distributed by order cycle" do
      distributor = create(:distributor_enterprise)
      product = create(:product)
      variant = product.variants.first
      create(:simple_order_cycle, distributors: [distributor], variants: [variant])

      expect(distributor.distributed_variants).to match_array [variant]
    end
  end

  describe "taxons" do
    let(:distributor) { create(:distributor_enterprise) }
    let(:supplier) { create(:supplier_enterprise) }
    let(:taxon1) { create(:taxon) }
    let(:taxon2) { create(:taxon) }
    let(:taxon3) { create(:taxon) }
    let(:product1) { create(:simple_product, primary_taxon: taxon1) }
    let(:product2) { create(:simple_product, primary_taxon: taxon2) }
    let(:product3) { create(:simple_product, primary_taxon: taxon3) }
    let(:oc) { create(:order_cycle) }
    let(:ex) {
      create(:exchange, order_cycle: oc, incoming: false, sender: supplier, receiver: distributor)
    }

    it "gets all taxons of all distributed products" do
      allow(Spree::Product).to receive(:in_distributor).and_return [product1, product2]
      expect(distributor.distributed_taxons).to match_array [taxon1, taxon2]
    end

    it "gets all taxons of all distributed products in open order cycles" do
      allow(Spree::Product).to receive(:in_distributor).and_return [product1, product2, product3]
      ex.variants << product1.variants.first
      ex.variants << product3.variants.first

      expect(distributor.current_distributed_taxons).to match_array [taxon1, taxon3]
    end

    it "gets all taxons of all supplied products" do
      allow(Spree::Product).to receive(:in_supplier).and_return [product1, product2]
      expect(supplier.supplied_taxons).to match_array [taxon1, taxon2]
    end
  end

  describe "presentation of attributes" do
    let(:distributor) {
      build_stubbed(:distributor_enterprise,
                    website: "http://www.google.com",
                    facebook: "www.facebook.com/roger",
                    linkedin: "https://linkedin.com",
                    instagram: "https://www.instagram.com/@insgram_user",
                    twitter: "www.twitter.com/@twitter_user")
    }

    it "strips http from url fields" do
      expect(distributor.website).to eq("www.google.com")
      expect(distributor.facebook).to eq("www.facebook.com/roger")
      expect(distributor.linkedin).to eq("linkedin.com")
    end

    it "strips @, http and domain address from url fields" do
      expect(distributor.instagram).to eq("insgram_user")
      expect(distributor.twitter).to eq("twitter_user")
    end
  end

  describe "producer properties" do
    let(:supplier) { create(:supplier_enterprise) }

    it "sets producer properties" do
      supplier.set_producer_property 'Organic Certified', 'NASAA 12345'

      expect(supplier.producer_properties.count).to eq(1)
      expect(supplier.producer_properties.first.value).to eq('NASAA 12345')
      expect(supplier.producer_properties.first.property.presentation).to eq('Organic Certified')
    end
  end

  describe "provide enterprise category" do
    let(:producer_sell_all) { build_stubbed(:enterprise, is_primary_producer: true,  sells: "any") }
    let(:producer_sell_own) { build_stubbed(:enterprise, is_primary_producer: true,  sells: "own") }
    let(:producer_sell_none) {
      build_stubbed(:enterprise, is_primary_producer: true, sells: "none")
    }
    let(:non_producer_sell_all) {
      build_stubbed(:enterprise, is_primary_producer: false,  sells: "any")
    }
    let(:non_producer_sell_own) {
      build_stubbed(:enterprise, is_primary_producer: false,  sells: "own")
    }
    let(:non_producer_sell_none) {
      build_stubbed(:enterprise, is_primary_producer: false, sells: "none")
    }

    it "should output enterprise categories" do
      expect(producer_sell_all.is_primary_producer).to eq(true)
      expect(producer_sell_all.sells).to eq("any")

      expect(producer_sell_all.category).to eq(:producer_hub)
      expect(producer_sell_own.category).to eq(:producer_shop)
      expect(producer_sell_none.category).to eq(:producer)
      expect(non_producer_sell_all.category).to eq(:hub)
      expect(non_producer_sell_own.category).to eq(:hub)
      expect(non_producer_sell_none.category).to eq(:hub_profile)
    end
  end

  describe "finding and automatically assigning a permalink" do
    let(:enterprise) { build_stubbed(:enterprise, name: "Name To Turn Into A Permalink") }
    it "assigns permalink when initialized" do
      allow(Enterprise).to receive(:find_available_permalink).and_return("available_permalink")
      expect(Enterprise).to receive(:find_available_permalink).with("Name To Turn Into A Permalink")
      expect do
        enterprise.__send__(:initialize_permalink)
      end.to change { enterprise.permalink }.to("available_permalink")
    end

    describe "finding a permalink" do
      let!(:enterprise1) { create(:enterprise, permalink: "permalink") }
      let!(:enterprise2) { create(:enterprise, permalink: "permalink1") }

      it "parameterizes the value provided" do
        expect(Enterprise.find_available_permalink("Some Unused Permalink"))
          .to eq "some-unused-permalink"
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

      it "should support permalink generation from names with non-roman characters" do
        enterprise = create(:enterprise, name: "你好")

        expect(enterprise.valid?).to be true
        expect(enterprise.permalink).to eq "ni-hao"
      end
    end
  end

  describe "#parents_of_one_union_others" do
    it "should return only parent producers" do
      supplier = create(:supplier_enterprise)
      distributor = create(:distributor_enterprise, is_primary_producer: false)
      permission = EnterpriseRelationshipPermission.new(name: "add_to_order_cycle")
      create(:enterprise_relationship, parent: distributor,
                                       child: supplier, permissions: [permission])
      expect(Enterprise.parents_of_one_union_others(supplier, nil)).to include(distributor)
    end

    it "should return other enterprise if it is passed as a second argument" do
      another_enterprise = create(:enterprise)
      supplier = create(:supplier_enterprise)
      distributor = create(:distributor_enterprise, is_primary_producer: false)
      permission = EnterpriseRelationshipPermission.new(name: "add_to_order_cycle")
      create(:enterprise_relationship, parent: distributor,
                                       child: supplier, permissions: [permission])
      expect(
        Enterprise.parents_of_one_union_others(supplier, another_enterprise)
      ).to include(another_enterprise)
    end

    it "does not find child in the relationship" do
      supplier = create(:supplier_enterprise)
      distributor = create(:distributor_enterprise, is_primary_producer: false)
      permission = EnterpriseRelationshipPermission.new(name: "add_to_order_cycle")
      create(:enterprise_relationship, parent: distributor,
                                       child: supplier, permissions: [permission])
      expect(Enterprise.parents_of_one_union_others(distributor, nil)).not_to include(supplier)
    end
  end

  describe "#plus_parents_and_order_cycle_producers" do
    it "does not find non-producers" do
      supplier = create(:supplier_enterprise)
      distributor = create(:distributor_enterprise, is_primary_producer: false)
      product = create(:product)
      order_cycle = create(
        :simple_order_cycle,
        suppliers: [supplier],
        distributors: [distributor],
        variants: [product.variants.first]
      )
      expect(distributor.plus_parents_and_order_cycle_producers(order_cycle)).to eq([supplier])
    end

    it "finds parent in the relationship" do
      supplier = create(:supplier_enterprise)
      distributor = create(:distributor_enterprise, is_primary_producer: false)
      permission = EnterpriseRelationshipPermission.new(name: "add_to_order_cycle")
      product = create(:product)
      order_cycle = create(
        :simple_order_cycle,
        distributors: [distributor],
        suppliers: [supplier],
        variants: [product.variants.first]
      )
      create(:enterprise_relationship, parent: distributor,
                                       child: supplier, permissions: [permission])
      expect(distributor.plus_parents_and_order_cycle_producers(order_cycle)).to include(supplier)
    end

    it "does not find child in the relationship" do
      supplier = create(:supplier_enterprise)
      distributor = create(:distributor_enterprise, is_primary_producer: false)
      permission = EnterpriseRelationshipPermission.new(name: "add_to_order_cycle")
      create(:enterprise_relationship, parent: distributor,
                                       child: supplier, permissions: [permission])
      product = create(:product)
      order_cycle = create(
        :simple_order_cycle,
        suppliers: [supplier],
        distributors: [distributor],
        variants: [product.variants.first]
      )
      expected = supplier.plus_parents_and_order_cycle_producers(order_cycle)
      expect(expected).not_to include(distributor)
    end

    it "it finds sender enterprises for order cycles that are passed" do
      supplier = create(:supplier_enterprise)
      sender = create(:supplier_enterprise)
      distributor = create(:distributor_enterprise, is_primary_producer: false)
      permission = EnterpriseRelationshipPermission.new(name: "add_to_order_cycle")
      create(:enterprise_relationship, parent: distributor, child: supplier,
                                       permissions: [permission])
      product = create(:product)
      order_cycle = create(
        :simple_order_cycle,
        suppliers: [sender],
        distributors: [distributor],
        variants: [product.variants.first]
      )
      expected = supplier.plus_parents_and_order_cycle_producers(order_cycle)
      expect(expected).to include(sender)
    end
  end

  describe "#is_producer_only" do
    context "when enterprise is_primary_producer and sells none" do
      it "returns true" do
        enterprise = build(:supplier_enterprise)
        expect(enterprise.is_producer_only).to be true
      end
    end

    context "when enterprise is_primary_producer and sells any" do
      it "returns false" do
        enterprise = build(:enterprise, is_primary_producer: true, sells: "any")
        expect(enterprise.is_producer_only).to be false
      end
    end

    context "when enterprise is_primary_producer and sells own" do
      it "returns false" do
        enterprise = build(:enterprise, is_primary_producer: true, sells: "own")
        expect(enterprise.is_producer_only).to be false
      end
    end
  end
end

def enterprise_name_error(owner_email)
  "has already been taken. \
If this is your enterprise and you would like to claim ownership, \
or if you would like to trade with this enterprise please contact \
the current manager of this profile at %s." % owner_email
end
