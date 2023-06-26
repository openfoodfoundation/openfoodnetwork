# frozen_string_literal: true

require 'spec_helper'
require 'open_food_network/permissions'

module OpenFoodNetwork
  describe Permissions do
    let(:user) { double(:user) }
    let(:permissions) { Permissions.new(user) }
    let(:permission) { 'one' }
    let(:e1) { create(:enterprise) }
    let(:e2) { create(:enterprise) }

    describe "finding managed and related enterprises granting a particular permission" do
      describe "as super admin" do
        before { allow(user).to receive(:admin?) { true } }

        it "returns all enterprises" do
          expect(permissions.send(:managed_and_related_enterprises_granting,
                                  :some_permission)).to match_array [e1, e2]
        end
      end

      describe "as an enterprise user" do
        let(:e3) { create(:enterprise) }
        before { allow(user).to receive(:admin?) { false } }

        it "returns only my managed enterprises any that have granting them P-OC" do
          expect(permissions).to receive(:managed_enterprises) { Enterprise.where(id: e1) }
          expect(permissions).to receive(:related_enterprises_granting).with(:some_permission) {
                                   Enterprise.where(id: e3).select(:id)
                                 }
          expect(permissions.send(:managed_and_related_enterprises_granting,
                                  :some_permission)).to match_array [e1, e3]
        end
      end
    end

    describe "finding managed & related enterprises granting or granted a particular permission" do
      describe "as super admin" do
        before { allow(user).to receive(:admin?) { true } }

        it "returns all enterprises" do
          expect(permissions.send(:managed_and_related_enterprises_granting,
                                  :some_permission)).to match_array [e1, e2]
        end
      end

      describe "as an enterprise user" do
        let(:e3) { create(:enterprise) }
        let(:e4) { create(:enterprise) }
        before { allow(user).to receive(:admin?) { false } }

        it "returns only my managed enterprises any that have granting them P-OC" do
          expect(permissions).to receive(:managed_enterprises) { Enterprise.where(id: e1) }
          expect(permissions).to receive(:related_enterprises_granting).with(:some_permission) {
                                   Enterprise.where(id: e3).select(:id)
                                 }
          expect(permissions).to receive(:related_enterprises_granted).with(:some_permission) {
                                   Enterprise.where(id: e4).select(:id)
                                 }
          expect(permissions.send(:managed_and_related_enterprises_with,
                                  :some_permission)).to match_array [e1, e3, e4]
        end
      end
    end

    describe "finding enterprises that can be selected in order report filters" do
      let(:e) { double(:enterprise) }

      it "returns managed and related enterprises with add_to_order_cycle permission" do
        expect(permissions).to receive(:managed_and_related_enterprises_with).
          with(:add_to_order_cycle).
          and_return([e])

        expect(permissions.visible_enterprises_for_order_reports).to eq [e]
      end
    end

    describe "finding visible enterprises" do
      let(:e) { double(:enterprise) }

      it "returns managed and related enterprises with add_to_order_cycle permission" do
        expect(permissions).to receive(:managed_and_related_enterprises_granting).
          with(:add_to_order_cycle).
          and_return([e])

        expect(permissions.visible_enterprises).to eq [e]
      end
    end

    describe "finding enterprises whose profiles can be edited" do
      let(:e) { double(:enterprise) }

      it "returns managed and related enterprises with edit_profile permission" do
        expect(permissions).
          to receive(:managed_and_related_enterprises_granting).
          with(:edit_profile).
          and_return([e])

        expect(permissions.editable_enterprises).to eq([e])
      end
    end

    describe "finding all producers for which we can create variant overrides" do
      let(:e1) { create(:supplier_enterprise) }
      let(:e2) { create(:supplier_enterprise) }

      it "compiles the list from variant_override_enterprises_per_hub" do
        allow(permissions).to receive(:variant_override_enterprises_per_hub) do
          { 1 => [e1.id], 2 => [e1.id, e2.id] }
        end

        expect(permissions.variant_override_producers).to match_array [e1, e2]
      end
    end

    describe "finding enterprises for which variant overrides can be created, for each hub" do
      let!(:hub) { create(:distributor_enterprise) }
      let!(:producer) { create(:supplier_enterprise) }
      let!(:er) {
        create(:enterprise_relationship, parent: producer, child: hub,
                                         permissions_list: [:create_variant_overrides])
      }

      before do
        allow(permissions).to receive(:managed_enterprises) { Enterprise.where(id: hub.id) }
        allow(permissions).to receive(:admin?) { false }
      end

      it "returns enterprises as hub_id => [producer, ...]" do
        expect(permissions.variant_override_enterprises_per_hub).to eq(
          hub.id => [producer.id]
        )
      end

      it "returns only permissions relating to managed hubs" do
        create(:enterprise_relationship, parent: e1, child: e2,
                                         permissions_list: [:create_variant_overrides])

        expect(permissions.variant_override_enterprises_per_hub).to eq(
          hub.id => [producer.id]
        )
      end

      it "returns only create_variant_overrides permissions" do
        allow(permissions).to receive(:managed_enterprises) { Enterprise.where(id: [hub, e2]) }
        create(:enterprise_relationship, parent: e1, child: e2,
                                         permissions_list: [:manage_products])

        expect(permissions.variant_override_enterprises_per_hub).to eq(
          hub.id => [producer.id]
        )
      end

      describe "hubs connected to the user by relationships only" do
        let!(:producer_managed) { create(:supplier_enterprise) }
        let!(:er_oc) {
          create(:enterprise_relationship, parent: hub, child: producer_managed,
                                           permissions_list: [:add_to_order_cycle,
                                                              :create_variant_overrides])
        }

        before do
          allow(permissions).to receive(:managed_enterprises) {
                                  Enterprise.where(id: producer_managed.id)
                                }
        end

        it "does not allow the user to create variant overrides for the hub" do
          expect(permissions.variant_override_enterprises_per_hub).to eq({})
        end
      end

      it "does not return managed producers (ie. only uses explicitly granted VO permissions)" do
        producer2 = create(:supplier_enterprise)
        allow(permissions).to receive(:managed_enterprises) {
                                Enterprise.where(id: [hub, producer2])
                              }

        expect(permissions.variant_override_enterprises_per_hub[hub.id]).to_not include producer2.id
      end

      it "returns itself if self is also a primary producer " \
         "(even when no explicit permission exists)" do
        hub.update_attribute(:is_primary_producer, true)

        expect(permissions.variant_override_enterprises_per_hub[hub.id]).to include hub.id
      end
    end

    describe "#editable_products" do
      let!(:p1) { create(:simple_product, supplier: create(:supplier_enterprise) ) }
      let!(:p2) { create(:simple_product, supplier: create(:supplier_enterprise) ) }

      before do
        allow(permissions).to receive(:managed_enterprise_products) { Spree::Product.where('1=0') }
        allow(permissions).to receive(:related_enterprises_granting).with(:manage_products) {
                                Enterprise.where("1=0").select(:id)
                              }
      end

      it "returns products produced by managed enterprises" do
        allow(user).to receive(:admin?) { false }
        allow(user).to receive(:enterprises) { [p1.supplier] }

        expect(permissions.editable_products).to eq([p1])
      end

      it "returns products produced by permitted enterprises" do
        allow(user).to receive(:admin?) { false }
        allow(user).to receive(:enterprises) { [] }
        allow(permissions).to receive(:related_enterprises_granting).
          with(:manage_products) { Enterprise.where(id: p2.supplier) }

        expect(permissions.editable_products).to eq([p2])
      end

      context "as superadmin" do
        it "returns all products" do
          allow(user).to receive(:admin?) { true }

          expect(permissions.editable_products).to include p1, p2
        end
      end
    end

    describe "finding visible products" do
      let!(:p1) { create(:simple_product, supplier: create(:supplier_enterprise) ) }
      let!(:p2) { create(:simple_product, supplier: create(:supplier_enterprise) ) }
      let!(:p3) { create(:simple_product, supplier: create(:supplier_enterprise) ) }

      before do
        allow(permissions).to receive(:managed_enterprise_products) { Spree::Product.where("1=0") }
        allow(permissions).to receive(:related_enterprises_granting).with(:manage_products) {
                                Enterprise.where("1=0").select(:id)
                              }
        allow(permissions).to receive(:related_enterprises_granting).with(:add_to_order_cycle) {
                                Enterprise.where("1=0").select(:id)
                              }
      end

      it "returns products produced by managed enterprises" do
        allow(user).to receive(:admin?) { false }
        allow(user).to receive(:enterprises) { Enterprise.where(id: p1.supplier_id) }

        expect(permissions.visible_products).to eq([p1])
      end

      it "returns products produced by enterprises that have granted manage products" do
        allow(user).to receive(:admin?) { false }
        allow(user).to receive(:enterprises) { [] }
        allow(permissions).to receive(:related_enterprises_granting).
          with(:manage_products) { Enterprise.where(id: p2.supplier) }

        expect(permissions.visible_products).to eq([p2])
      end

      it "returns products produced by enterprises that have granted P-OC" do
        allow(user).to receive(:admin?) { false }
        allow(user).to receive(:enterprises) { [] }
        allow(permissions).to receive(:related_enterprises_granting).
          with(:add_to_order_cycle) { Enterprise.where(id: p3.supplier).select(:id) }

        expect(permissions.visible_products).to eq([p3])
      end

      context "as superadmin" do
        it "returns all products" do
          allow(user).to receive(:admin?) { true }

          expect(permissions.visible_products.to_a).to include p1, p2, p3
        end
      end
    end

    describe "finding enterprises that we manage products for" do
      let(:e) { double(:enterprise) }

      it "returns managed and related enterprises with manage_products permission" do
        expect(permissions).
          to receive(:managed_and_related_enterprises_granting).
          with(:manage_products).
          and_return([e])

        expect(permissions.managed_product_enterprises).to eq([e])
      end
    end

    ########################################

    describe "finding related enterprises with a particular permission" do
      let!(:er) {
        create(:enterprise_relationship, parent: e1, child: e2, permissions_list: [permission])
      }

      it "returns the enterprises" do
        allow(permissions).to receive(:managed_enterprises) { Enterprise.where(id: e2) }
        expect(permissions.send(:related_enterprises_granting, permission)).to eq([e1])
      end

      it "returns an empty array when there are none" do
        allow(permissions).to receive(:managed_enterprises) { Enterprise.where(id: e1) }
        expect(permissions.send(:related_enterprises_granting, permission)).to eq([])
      end
    end

    describe "finding enterprises that are managed or with a particular permission" do
      before do
        allow(permissions).to receive(:managed_enterprises) { Enterprise.where('1=0') }
        allow(permissions).to receive(:related_enterprises_granting) {
                                Enterprise.where('1=0').select(:id)
                              }
        allow(permissions).to receive(:admin?) { false }
      end

      it "returns managed enterprises" do
        expect(permissions).to receive(:managed_enterprises) { Enterprise.where(id: e1) }
        expect(permissions.send(:managed_and_related_enterprises_granting, permission)).to eq([e1])
      end

      it "returns permitted enterprises" do
        expect(permissions).to receive(:related_enterprises_granting).with(permission).
          and_return(Enterprise.where(id: e2).select(:id))
        expect(permissions.send(:managed_and_related_enterprises_granting, permission)).to eq([e2])
      end
    end

    describe "finding visible subscriptions" do
      let!(:so1) { create(:subscription) }
      let!(:so2) { create(:subscription) }

      it "returns subscriptions placed with managed shops" do
        expect(permissions).to receive(:managed_enterprises) { [so1.shop] }

        expect(permissions.visible_subscriptions).to eq [so1]
      end
    end
  end
end
