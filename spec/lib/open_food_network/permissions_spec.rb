require 'open_food_network/permissions'

module OpenFoodNetwork
  describe Permissions do
    let(:user) { double(:user) }
    let(:permissions) { Permissions.new(user) }
    let(:permission) { 'one' }
    let(:e1) { create(:enterprise) }
    let(:e2) { create(:enterprise) }

    describe "finding enterprises that can be added to an order cycle" do
      let(:e) { double(:enterprise) }

      it "returns managed and related enterprises with add_to_order_cycle permission" do
        allow(user).to receive(:admin?) { false }
        expect(permissions).to receive(:managed_and_related_enterprises_with).
          with(:add_to_order_cycle).
          and_return([e])

        expect(permissions.enterprises_managed_or_granting_add_to_order_cycle).to eq [e]
      end

      it "shows all enterprises for admin user" do
        allow(user).to receive(:admin?) { true }

        expect(permissions.enterprises_managed_or_granting_add_to_order_cycle).to eq [e1, e2]
      end
    end

    describe "finding enterprises whose profiles can be edited" do
      let(:e) { double(:enterprise) }

      it "returns managed and related enterprises with edit_profile permission" do
        permissions.
          should_receive(:managed_and_related_enterprises_with).
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

        permissions.variant_override_producers.sort.should == [e1, e2].sort
      end
    end

    describe "finding enterprises for which variant overrides can be created, for each hub" do
      let!(:hub) { create(:distributor_enterprise) }
      let!(:producer) { create(:supplier_enterprise) }
      let!(:er) { create(:enterprise_relationship, parent: producer, child: hub,
                         permissions_list: [:create_variant_overrides]) }

      before do
        permissions.stub(:managed_enterprises) { Enterprise.where(id: hub.id) }
      end

      it "returns enterprises as hub_id => [producer, ...]" do
        permissions.variant_override_enterprises_per_hub.should ==
          {hub.id => [producer.id]}
      end

      it "returns only permissions relating to managed enterprises" do
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
        # producer_managed can add hub to order cycle
        # hub can create variant overrides for producer
        # we manage producer_managed
        # therefore, we should be able to create variant overrides for hub on producer's products

        let!(:producer_managed) { create(:supplier_enterprise) }
        let!(:er_oc) { create(:enterprise_relationship, parent: hub, child: producer_managed,
                              permissions_list: [:add_to_order_cycle]) }

        before do
          permissions.stub(:managed_enterprises) { Enterprise.where(id: producer_managed.id) }
        end

        it "allows the hub to create variant overrides for the producer" do
          permissions.variant_override_enterprises_per_hub.should ==
            {hub.id => [producer.id, producer_managed.id]}
        end
      end

      it "also returns managed producers" do
        producer2 = create(:supplier_enterprise)
        permissions.stub(:managed_enterprises) { Enterprise.where(id: [hub, producer2]) }

        permissions.variant_override_enterprises_per_hub.should ==
          {hub.id => [producer.id, producer2.id]}
      end
    end

    describe "finding managed products" do
      let!(:p1) { create(:simple_product) }
      let!(:p2) { create(:simple_product) }

      before do
        permissions.stub(:managed_enterprise_products) { Spree::Product.where('1=0') }
        permissions.stub(:related_enterprise_products) { Spree::Product.where('1=0') }
      end

      it "returns products produced by managed enterprises" do
        permissions.stub(:managed_enterprise_products) { Spree::Product.where(id: p1) }
        permissions.managed_products.should == [p1]
      end

      it "returns products produced by permitted enterprises" do
        permissions.stub(:related_enterprise_products) { Spree::Product.where(id: p2) }
        permissions.managed_products.should == [p2]
      end
    end

    describe "finding enterprises that we manage products for" do
      let(:e) { double(:enterprise) }

      it "returns managed and related enterprises with manage_products permission" do
        permissions.
          should_receive(:managed_and_related_enterprises_with).
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
        permissions.send(:related_enterprises_with, permission).should == [e1]
      end

      it "returns an empty array when there are none" do
        permissions.stub(:managed_enterprises) { e1 }
        permissions.send(:related_enterprises_with, permission).should == []
      end
    end

    describe "finding enterprises that are managed or with a particular permission" do
      before do
        permissions.stub(:managed_enterprises) { Enterprise.where('1=0') }
        permissions.stub(:related_enterprises_with) { Enterprise.where('1=0') }
      end

      it "returns managed enterprises" do
        permissions.should_receive(:managed_enterprises) { Enterprise.where(id: e1) }
        permissions.send(:managed_and_related_enterprises_with, permission).should == [e1]
      end

      it "returns permitted enterprises" do
        permissions.should_receive(:related_enterprises_with).with(permission).
          and_return(Enterprise.where(id: e2))
        permissions.send(:managed_and_related_enterprises_with, permission).should == [e2]
      end
    end

    describe "finding the supplied products of related enterprises" do
      let!(:e) { create(:enterprise) }
      let!(:p) { create(:simple_product, supplier: e) }

      it "returns supplied products" do
        permissions.should_receive(:related_enterprises_with).with(:manage_products) { [e] }

        permissions.send(:related_enterprise_products).should == [p]
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
  end
end
