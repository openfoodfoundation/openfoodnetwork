# frozen_string_literal: true

require 'spec_helper'

describe EnterpriseRelationship do
  describe "scopes" do
    let(:e1)  { create(:enterprise, name: 'A') }
    let(:e2)  { create(:enterprise, name: 'B') }
    let(:e3)  { create(:enterprise, name: 'C') }

    it "sorts by child, parent enterprise name" do
      er1 = create(:enterprise_relationship, parent: e3, child: e1)
      er2 = create(:enterprise_relationship, parent: e1, child: e2)
      er3 = create(:enterprise_relationship, parent: e2, child: e1)

      expect(EnterpriseRelationship.by_name).to eq([er3, er1, er2])
    end

    describe "finding relationships involving some enterprises" do
      let!(:er) { create(:enterprise_relationship, parent: e1, child: e2) }

      it "returns relationships where an enterprise is the parent" do
        expect(EnterpriseRelationship.involving_enterprises([e1])).to eq([er])
      end

      it "returns relationships where an enterprise is the child" do
        expect(EnterpriseRelationship.involving_enterprises([e2])).to eq([er])
      end

      it "does not return other relationships" do
        expect(EnterpriseRelationship.involving_enterprises([e3])).to eq([])
      end
    end

    describe "creating with a permission list" do
      context "creating a new list of permissions" do
        it "creates a new permission for each item in the list" do
          er = EnterpriseRelationship.create! parent: e1, child: e2,
                                              permissions_list: ['one', 'two']
          er.reload
          expect(er.permissions.map(&:name)).to match_array ['one', 'two']
        end

        it "does nothing when the list is nil" do
          er = EnterpriseRelationship.create! parent: e1, child: e2, permissions_list: nil
          er.reload
          expect(er.permissions).to be_empty
        end
      end

      context "updating an existing list of permissions" do
        let(:er) {
          create(:enterprise_relationship, parent: e1, child: e2,
                                           permissions_list: ["one", "two", "three"])
        }
        it "creates a new permission for each item in the list that has no existing permission" do
          er.permissions_list = ['four']
          er.save!
          er.reload
          expect(er.permissions.map(&:name)).to include 'four'
        end

        it "does not duplicate existing permissions" do
          er.permissions_list = ["one", "two", "three"]
          er.save!
          er.reload
          expect(er.permissions.map(&:name).count).to eq(3)
          expect(er.permissions.map(&:name)).to match_array ["one", "two", "three"]
        end

        it "removes permissions that are not in the list" do
          er.permissions_list = ['one', 'three']
          er.save!
          er.reload
          expect(er.permissions.map(&:name)).to include 'one', 'three'
          expect(er.permissions.map(&:name)).not_to include 'two'
        end

        it "does removes all permissions when the list provided is nil" do
          er.permissions_list = nil
          er.save!
          er.reload
          expect(er.permissions).to be_empty
        end
      end
    end

    describe "finding by permission" do
      let!(:er1) { create(:enterprise_relationship, parent: e2, child: e1) }
      let!(:er2) { create(:enterprise_relationship, parent: e3, child: e2) }
      let!(:er3) { create(:enterprise_relationship, parent: e1, child: e3) }

      it "finds relationships that grant permissions to some enterprises" do
        expect(EnterpriseRelationship.permitting([e1, e2])).to match_array [er1, er2]
      end

      it "finds relationships that are granted by particular enterprises" do
        expect(EnterpriseRelationship.permitted_by([e1, e2])).to match_array [er1, er3]
      end
    end

    it "finds relationships that grant a particular permission" do
      er1 = create(:enterprise_relationship, parent: e1, child: e2,
                                             permissions_list: ['one', 'two'])
      er2 = create(:enterprise_relationship, parent: e2, child: e3,
                                             permissions_list: ['two', 'three'])
      er3 = create(:enterprise_relationship, parent: e3, child: e1,
                                             permissions_list: ['three', 'four'])

      expect(EnterpriseRelationship.with_permission('two')).to match_array [er1, er2]
    end
  end

  describe "finding relatives" do
    let(:e1) { create(:supplier_enterprise) }
    let(:e2) { create(:distributor_enterprise) }
    let!(:er) { create(:enterprise_relationship, parent: e1, child: e2) }
    let(:er_reverse) { create(:enterprise_relationship, parent: e2, child: e1) }

    it "includes self where appropriate" do
      expect(EnterpriseRelationship.relatives[e2.id][:distributors]).to include e2.id
      expect(EnterpriseRelationship.relatives[e2.id][:producers]).not_to include e2.id
    end

    it "categorises enterprises into distributors and producers" do
      e2.update_attribute :is_primary_producer, true
      expect(EnterpriseRelationship.relatives).to eq(
        e1.id => { distributors: Set.new([e2.id]), producers: Set.new([e1.id, e2.id]) },
        e2.id => { distributors: Set.new([e2.id]), producers: Set.new([e2.id, e1.id]) }
      )
    end

    it "finds inactive enterprises by default" do
      e1.update_attribute :sells, 'unspecified'
      expect(EnterpriseRelationship.relatives[e2.id][:producers]).to eq(Set.new([e1.id]))
    end

    it "does not find inactive enterprises when requested" do
      e1.update_attribute :sells, 'unspecified'
      expect(EnterpriseRelationship.relatives(true)[e2.id][:producers]).to be_empty
    end

    it "does not show duplicates" do
      er_reverse
      expect(EnterpriseRelationship.relatives[e2.id][:producers]).to eq(Set.new([e1.id]))
    end
  end

  describe "callbacks" do
    describe "updating variant override permissions" do
      let(:hub) { create(:distributor_enterprise) }
      let(:producer) { create(:supplier_enterprise) }
      let(:some_other_producer) { create(:supplier_enterprise) }

      context "when variant_override permission is present" do
        let!(:er) {
          create(:enterprise_relationship, child: hub, parent: producer,
                                           permissions_list: [:add_to_order_cycles,
                                                              :create_variant_overrides] )
        }
        let!(:some_other_er) {
          create(:enterprise_relationship, child: hub, parent: some_other_producer,
                                           permissions_list: [:add_to_order_cycles,
                                                              :create_variant_overrides] )
        }
        let!(:vo1) {
          create(:variant_override, hub: hub,
                                    variant: create(
                                      :variant,
                                      product: create(
                                        :product, supplier: producer
                                      )
                                    ))
        }
        let!(:vo2) {
          create(:variant_override, hub: hub,
                                    variant: create(
                                      :variant,
                                      product: create(
                                        :product, supplier: producer
                                      )
                                    ))
        }
        let!(:vo3) {
          create(:variant_override, hub: hub,
                                    variant: create(
                                      :variant,
                                      product: create(
                                        :product, supplier: some_other_producer
                                      )
                                    ))
        }

        context "revoking variant override permissions" do
          context "when the enterprise relationship is destroyed" do
            before { er.destroy }
            it "should set permission_revoked_at to the current time " \
               "for all variant overrides of the relationship" do
              expect(vo1.reload.permission_revoked_at).to_not be_nil
              expect(vo2.reload.permission_revoked_at).to_not be_nil
              expect(vo2.reload.permission_revoked_at).to_not be_nil
            end
          end
        end

        context "and is then removed" do
          before { er.permissions_list = [:add_to_order_cycles]; er.save! }
          it "should set permission_revoked_at to the current time " \
             "for all relevant variant overrides" do
            expect(vo1.reload.permission_revoked_at).to_not be_nil
            expect(vo2.reload.permission_revoked_at).to_not be_nil
          end

          it "should not affect other variant overrides" do
            expect(vo3.reload.permission_revoked_at).to be_nil
          end
        end

        context "and then some other permission is removed" do
          before { er.permissions_list = [:create_variant_overrides]; er.save! }

          it "should have no effect on existing variant_overrides" do
            expect(vo1.reload.permission_revoked_at).to be_nil
            expect(vo2.reload.permission_revoked_at).to be_nil
            expect(vo3.reload.permission_revoked_at).to be_nil
          end
        end
      end

      context "when variant_override permission is not present" do
        let!(:er) {
          create(:enterprise_relationship, child: hub, parent: producer,
                                           permissions_list: [:add_to_order_cycles] )
        }
        let!(:some_other_er) {
          create(:enterprise_relationship, child: hub, parent: some_other_producer,
                                           permissions_list: [:add_to_order_cycles] )
        }
        let!(:vo1) {
          create(:variant_override, hub: hub,
                                    variant: create(
                                      :variant,
                                      product: create(
                                        :product, supplier: producer
                                      )
                                    ),
                                    permission_revoked_at: Time.now.in_time_zone)
        }
        let!(:vo2) {
          create(:variant_override, hub: hub,
                                    variant: create(
                                      :variant,
                                      product: create(
                                        :product, supplier: producer
                                      )
                                    ),
                                    permission_revoked_at: Time.now.in_time_zone)
        }
        let!(:vo3) {
          create(:variant_override, hub: hub,
                                    variant: create(
                                      :variant,
                                      product: create(
                                        :product, supplier: some_other_producer
                                      )
                                    ),
                                    permission_revoked_at: Time.now.in_time_zone)
        }

        context "and is then added" do
          before {
            er.permissions_list = [:add_to_order_cycles, :create_variant_overrides]; er.save!
          }
          it "should set permission_revoked_at to nil for all relevant variant overrides" do
            expect(vo1.reload.permission_revoked_at).to be_nil
            expect(vo2.reload.permission_revoked_at).to be_nil
          end

          it "should not affect other variant overrides" do
            expect(vo3.reload.permission_revoked_at).to_not be_nil
          end
        end

        context "and then some other permission is added" do
          before { er.permissions_list = [:add_to_order_cycles, :manage_products]; er.save! }

          it "should have no effect on existing variant_overrides" do
            expect(vo1.reload.permission_revoked_at).to_not be_nil
            expect(vo2.reload.permission_revoked_at).to_not be_nil
            expect(vo3.reload.permission_revoked_at).to_not be_nil
          end
        end
      end
    end
    describe "updating order cycles" do
      let(:hub) { create(:distributor_enterprise) }
      let(:producer) { create(:supplier_enterprise) }
      let(:order_cycle) { create(:simple_order_cycle) }
      let(:some_other_producer) { create(:supplier_enterprise) }

      context "when order_cycle permission is present" do
        let!(:er) {
          create(:enterprise_relationship, child: hub, parent: producer,
                                           permissions_list: [
                                             :add_to_order_cycle,
                                             :create_variant_overrides
                                           ] )
        }
        let!(:incoming_external_exchange) {
          order_cycle.exchanges.create! sender: producer, receiver: hub, incoming: true
        }
        let!(:other_external_exchange) {
          order_cycle.exchanges.create! sender: some_other_producer, receiver: hub, incoming: true
        }
        let!(:incoming_internal_exchange) {
          order_cycle.exchanges.create! sender: hub, receiver: hub, incoming: true
        }
        let!(:outgoing_internal_exchange) {
          order_cycle.exchanges.create! sender: hub, receiver: hub, incoming: false
        }
        let!(:variant) { create(:variant) }
        let!(:some_other_variant) { create(:variant) }
        let!(:incoming_external_variant) {
          incoming_external_exchange.exchange_variants.create!(
            exchange: incoming_external_exchange, variant: variant
          )
        }
        let!(:incoming_internal_only_variant) {
          incoming_internal_exchange.exchange_variants.create!(
            exchange: incoming_internal_exchange, variant: some_other_variant
          )
        }
        let!(:outgoing_internal_variant) {
          outgoing_internal_exchange.exchange_variants.create!(
            exchange: outgoing_internal_exchange, variant: variant
          )
        }
        let!(:outgoing_internal_only_variant) {
          outgoing_internal_exchange.exchange_variants.create!(
            exchange: outgoing_internal_exchange, variant: some_other_variant
          )
        }

        # We need to destroy the exchange variants on all order cycles related to the ER if
        # 'add_to_order_cycle' permission is removed. If they are left on the order cycle, the
        # Taxons of the variants will still appear on the /shops page, despite the hub not
        # actually offering the variants anymore.
        context "removing exchanges and exchange variants" do
          context "when the enterprise relationship is destroyed" do
            before { er.destroy }
            it "should destroy all exchanges and exchange variants related to ER" do
              expect(Exchange.exists?(incoming_external_exchange.id)).to be false
              expect(Exchange.exists?(other_external_exchange.id)).to be true
              expect(ExchangeVariant.exists?(incoming_external_variant.id)).to be false
              expect(ExchangeVariant.exists?(outgoing_internal_variant.id)).to be false
              expect(ExchangeVariant.exists?(incoming_internal_only_variant.id)).to be true
              expect(ExchangeVariant.exists?(outgoing_internal_only_variant.id)).to be true
            end
          end
        end

        context "and is then removed" do
          before { er.permissions_list = [:create_variant_overrides]; er.save! }
          it "should destroy all exchanges and exchange variants related to ER" do
            expect(Exchange.exists?(incoming_external_exchange.id)).to be false
            expect(Exchange.exists?(other_external_exchange.id)).to be true
            expect(ExchangeVariant.exists?(incoming_external_variant.id)).to be false
            expect(ExchangeVariant.exists?(outgoing_internal_variant.id)).to be false
            expect(ExchangeVariant.exists?(incoming_internal_only_variant.id)).to be true
            expect(ExchangeVariant.exists?(outgoing_internal_only_variant.id)).to be true
          end

          it "should not affect other exchanges or order cycles" do
            expect(Exchange.exists?(outgoing_internal_exchange.id)).to be true
          end
        end

        context "and then some other permission is removed" do
          before { er.permissions_list = [:add_to_order_cycle]; er.save! }
          it "should have no effect on existing exchanges" do
            expect(Exchange.exists?(incoming_external_exchange.id)).to be true
            expect(Exchange.exists?(other_external_exchange.id)).to be true
            expect(ExchangeVariant.exists?(incoming_external_variant.id)).to be true
            expect(ExchangeVariant.exists?(outgoing_internal_variant.id)).to be true
            expect(ExchangeVariant.exists?(incoming_internal_only_variant.id)).to be true
            expect(ExchangeVariant.exists?(outgoing_internal_only_variant.id)).to be true
          end
        end
      end
    end
  end
end
