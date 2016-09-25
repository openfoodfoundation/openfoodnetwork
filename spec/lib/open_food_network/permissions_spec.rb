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
          expect(permissions.send(:managed_and_related_enterprises_granting, :some_permission)).to match_array [e1, e2]
        end
      end

      describe "as an enterprise user" do
        let(:e3) { create(:enterprise) }
        before { allow(user).to receive(:admin?) { false } }

        it "returns only my managed enterprises any that have granting them P-OC" do
          expect(permissions).to receive(:managed_enterprises) { Enterprise.where(id: e1) }
          expect(permissions).to receive(:related_enterprises_granting).with(:some_permission) { Enterprise.where(id: e3) }
          expect(permissions.send(:managed_and_related_enterprises_granting, :some_permission)).to match_array [e1, e3]
        end
      end
    end

    describe "finding managed and related enterprises granting or granted a particular permission" do
      describe "as super admin" do
        before { allow(user).to receive(:admin?) { true } }

        it "returns all enterprises" do
          expect(permissions.send(:managed_and_related_enterprises_granting, :some_permission)).to match_array [e1, e2]
        end
      end

      describe "as an enterprise user" do
        let(:e3) { create(:enterprise) }
        let(:e4) { create(:enterprise) }
        before { allow(user).to receive(:admin?) { false } }

        it "returns only my managed enterprises any that have granting them P-OC" do
          expect(permissions).to receive(:managed_enterprises) { Enterprise.where(id: e1) }
          expect(permissions).to receive(:related_enterprises_granting).with(:some_permission) { Enterprise.where(id: e3) }
          expect(permissions).to receive(:related_enterprises_granted).with(:some_permission) { Enterprise.where(id: e4) }
          expect(permissions.send(:managed_and_related_enterprises_with, :some_permission)).to match_array [e1, e3, e4]
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
        permissions.
          should_receive(:managed_and_related_enterprises_granting).
          with(:edit_profile).
          and_return([e])

        permissions.editable_enterprises.should == [e]
      end
    end

    describe "finding all producers for which we can create variant overrides" do
      let(:e1) { create(:supplier_enterprise) }
      let(:e2) { create(:supplier_enterprise) }

      it "compiles the list from variant_override_enterprises_per_hub" do
        permissions.stub(:variant_override_enterprises_per_hub) do
          {1 => [e1.id], 2 => [e1.id, e2.id]}
        end

        permissions.variant_override_producers.should match_array [e1, e2]
      end
    end

    describe "finding enterprises for which variant overrides can be created, for each hub" do
      let!(:hub) { create(:distributor_enterprise) }
      let!(:producer) { create(:supplier_enterprise) }
      let!(:er) { create(:enterprise_relationship, parent: producer, child: hub,
                         permissions_list: [:create_variant_overrides]) }

      before do
        permissions.stub(:managed_enterprises) { Enterprise.where(id: hub.id) }
        permissions.stub(:admin?) { false }
      end

      it "returns enterprises as hub_id => [producer, ...]" do
        permissions.variant_override_enterprises_per_hub.should ==
          {hub.id => [producer.id]}
      end

      it "returns only permissions relating to managed hubs" do
        create(:enterprise_relationship, parent: e1, child: e2,
                         permissions_list: [:create_variant_overrides])

        permissions.variant_override_enterprises_per_hub.should ==
          {hub.id => [producer.id]}
      end

      it "returns only create_variant_overrides permissions" do
        permissions.stub(:managed_enterprises) { Enterprise.where(id: [hub, e2]) }
        create(:enterprise_relationship, parent: e1, child: e2,
                         permissions_list: [:manage_products])

        permissions.variant_override_enterprises_per_hub.should ==
          {hub.id => [producer.id]}
      end

      describe "hubs connected to the user by relationships only" do
        let!(:producer_managed) { create(:supplier_enterprise) }
        let!(:er_oc) { create(:enterprise_relationship, parent: hub, child: producer_managed,
                              permissions_list: [:add_to_order_cycle, :create_variant_overrides]) }

        before do
          permissions.stub(:managed_enterprises) { Enterprise.where(id: producer_managed.id) }
        end

        it "does not allow the user to create variant overrides for the hub" do
          permissions.variant_override_enterprises_per_hub.should == {}
        end
      end

      it "does not return managed producers (ie. only uses explicitly granted VO permissions)" do
        producer2 = create(:supplier_enterprise)
        permissions.stub(:managed_enterprises) { Enterprise.where(id: [hub, producer2]) }

        expect(permissions.variant_override_enterprises_per_hub[hub.id]).to_not include producer2.id
      end

      it "returns itself if self is also a primary producer (even when no explicit permission exists)" do
        hub.update_attribute(:is_primary_producer, true)

        expect(permissions.variant_override_enterprises_per_hub[hub.id]).to include hub.id
      end
    end

    describe "finding editable products" do
      let!(:p1) { create(:simple_product, supplier: create(:supplier_enterprise) ) }
      let!(:p2) { create(:simple_product, supplier: create(:supplier_enterprise) ) }

      before do
        permissions.stub(:managed_enterprise_products) { Spree::Product.where('1=0') }
        allow(permissions).to receive(:related_enterprises_granting).with(:manage_products) { Enterprise.where("1=0") }
      end

      it "returns products produced by managed enterprises" do
        permissions.stub(:managed_enterprise_products) { Spree::Product.where(id: p1) }
        permissions.editable_products.should == [p1]
      end

      it "returns products produced by permitted enterprises" do
        allow(permissions).to receive(:related_enterprises_granting).
          with(:manage_products) { Enterprise.where(id: p2.supplier) }
        permissions.editable_products.should == [p2]
      end
    end

    describe "finding visible products" do
      let!(:p1) { create(:simple_product, supplier: create(:supplier_enterprise) ) }
      let!(:p2) { create(:simple_product, supplier: create(:supplier_enterprise) ) }
      let!(:p3) { create(:simple_product, supplier: create(:supplier_enterprise) ) }

      before do
        permissions.stub(:managed_enterprise_products) { Spree::Product.where("1=0") }
        allow(permissions).to receive(:related_enterprises_granting).with(:manage_products) { Enterprise.where("1=0") }
        allow(permissions).to receive(:related_enterprises_granting).with(:add_to_order_cycle) { Enterprise.where("1=0") }
      end

      it "returns products produced by managed enterprises" do
        permissions.stub(:managed_enterprise_products) { Spree::Product.where(id: p1) }
        permissions.visible_products.should == [p1]
      end

      it "returns products produced by enterprises that have granted manage products" do
        allow(permissions).to receive(:related_enterprises_granting).
          with(:manage_products) { Enterprise.where(id: p2.supplier) }
        permissions.visible_products.should == [p2]
      end

      it "returns products produced by enterprises that have granted P-OC" do
        allow(permissions).to receive(:related_enterprises_granting).
          with(:add_to_order_cycle) { Enterprise.where(id: p3.supplier) }
        permissions.visible_products.should == [p3]
      end
    end

    describe "finding enterprises that we manage products for" do
      let(:e) { double(:enterprise) }

      it "returns managed and related enterprises with manage_products permission" do
        permissions.
          should_receive(:managed_and_related_enterprises_granting).
          with(:manage_products).
          and_return([e])

        permissions.managed_product_enterprises.should == [e]
      end
    end

    ########################################

    describe "finding related enterprises with a particular permission" do
      let!(:er) { create(:enterprise_relationship, parent: e1, child: e2, permissions_list: [permission]) }

      it "returns the enterprises" do
        permissions.stub(:managed_enterprises) { e2 }
        permissions.send(:related_enterprises_granting, permission).should == [e1]
      end

      it "returns an empty array when there are none" do
        permissions.stub(:managed_enterprises) { e1 }
        permissions.send(:related_enterprises_granting, permission).should == []
      end
    end

    describe "finding enterprises that are managed or with a particular permission" do
      before do
        permissions.stub(:managed_enterprises) { Enterprise.where('1=0') }
        permissions.stub(:related_enterprises_granting) { Enterprise.where('1=0') }
        permissions.stub(:admin?) { false }
      end

      it "returns managed enterprises" do
        permissions.should_receive(:managed_enterprises) { Enterprise.where(id: e1) }
        permissions.send(:managed_and_related_enterprises_granting, permission).should == [e1]
      end

      it "returns permitted enterprises" do
        permissions.should_receive(:related_enterprises_granting).with(permission).
          and_return(Enterprise.where(id: e2))
        permissions.send(:managed_and_related_enterprises_granting, permission).should == [e2]
      end
    end

    describe "finding orders that are visible in reports" do
      let(:distributor) { create(:distributor_enterprise) }
      let(:coordinator) { create(:distributor_enterprise) }
      let(:random_enterprise) { create(:distributor_enterprise) }
      let(:order_cycle) { create(:simple_order_cycle, coordinator: coordinator, distributors: [distributor]) }
      let(:order) { create(:order, order_cycle: order_cycle, distributor: distributor ) }
      let!(:line_item) { create(:line_item, order: order) }
      let!(:producer) { create(:supplier_enterprise) }

      before do
        permissions.stub(:coordinated_order_cycles) { Enterprise.where("1=0") }
      end

      context "as the hub through which the order was placed" do
        before do
          permissions.stub(:managed_enterprises) { Enterprise.where(id: distributor) }
        end

        it "should let me see the order" do
          expect(permissions.visible_orders).to include order
        end
      end

      context "as the coordinator of the order cycle through which the order was placed" do
        before do
          permissions.stub(:managed_enterprises) { Enterprise.where(id: coordinator) }
          permissions.stub(:coordinated_order_cycles) { OrderCycle.where(id: order_cycle) }
        end

        it "should let me see the order" do
          expect(permissions.visible_orders).to include order
        end
      end

      context "as a producer which has granted P-OC to the distributor of an order" do
        before do
          permissions.stub(:managed_enterprises) { Enterprise.where(id: producer) }
          create(:enterprise_relationship, parent: producer, child: distributor, permissions_list: [:add_to_order_cycle])
        end

        context "which contains my products" do
          before do
            line_item.product.supplier = producer
            line_item.product.save
          end

          it "should let me see the order" do
            expect(permissions.visible_orders).to include order
          end
        end

        context "which does not contain my products" do
          it "should not let me see the order" do
            expect(permissions.visible_orders).to_not include order
          end
        end
      end

      context "as an enterprise that is a distributor in the order cycle, but not the distributor of the order" do
        before do
          permissions.stub(:managed_enterprises) { Enterprise.where(id: random_enterprise) }
        end

        it "should not let me see the order" do
          expect(permissions.visible_orders).to_not include order
        end
      end
    end

    describe "finding line items that are visible in reports" do
      let(:distributor) { create(:distributor_enterprise) }
      let(:coordinator) { create(:distributor_enterprise) }
      let(:random_enterprise) { create(:distributor_enterprise) }
      let(:order_cycle) { create(:simple_order_cycle, coordinator: coordinator, distributors: [distributor]) }
      let(:order) { create(:order, order_cycle: order_cycle, distributor: distributor ) }
      let!(:line_item1) { create(:line_item, order: order) }
      let!(:line_item2) { create(:line_item, order: order) }
      let!(:producer) { create(:supplier_enterprise) }

      before do
        permissions.stub(:coordinated_order_cycles) { Enterprise.where("1=0") }
      end

      context "as the hub through which the parent order was placed" do
        before do
          permissions.stub(:managed_enterprises) { Enterprise.where(id: distributor) }
        end

        it "should let me see the line_items" do
          expect(permissions.visible_line_items).to include line_item1, line_item2
        end
      end

      context "as the coordinator of the order cycle through which the parent order was placed" do
        before do
          permissions.stub(:managed_enterprises) { Enterprise.where(id: coordinator) }
          permissions.stub(:coordinated_order_cycles) { OrderCycle.where(id: order_cycle) }
        end

        it "should let me see the line_items" do
          expect(permissions.visible_line_items).to include line_item1, line_item2
        end
      end

      context "as the manager producer which has granted P-OC to the distributor of the parent order" do
        before do
          permissions.stub(:managed_enterprises) { Enterprise.where(id: producer) }
          create(:enterprise_relationship, parent: producer, child: distributor, permissions_list: [:add_to_order_cycle])

          line_item1.product.supplier = producer
          line_item1.product.save
        end

        it "should let me see the line_items pertaining to variants I produce" do
          ps = permissions.visible_line_items
          expect(ps).to include line_item1
          expect(ps).to_not include line_item2
        end
      end

      context "as an enterprise that is a distributor in the order cycle, but not the distributor of the parent order" do
        before do
          permissions.stub(:managed_enterprises) { Enterprise.where(id: random_enterprise) }
        end

        it "should not let me see the line_items" do
          expect(permissions.visible_line_items).to_not include line_item1, line_item2
        end
      end
    end

    describe "finding visible standing orders" do
      let!(:so1) { create(:standing_order) }
      let!(:so2) { create(:standing_order) }

      it "returns standing orders placed with managed shops" do
        expect(permissions).to receive(:managed_enterprises) { [so1.shop] }

        expect(permissions.visible_standing_orders).to eq [so1]
      end
    end
  end
end
