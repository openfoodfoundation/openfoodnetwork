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
        permissions.
          should_receive(:managed_and_related_enterprises_with).
          with(:add_to_order_cycle).
          and_return([e])

        permissions.order_cycle_enterprises.should == [e]
      end
    end

    describe "finding enterprises that can be viewed in the order cycle interface" do
      let(:coordinator) { create(:distributor_enterprise) }
      let(:hub) { create(:distributor_enterprise) }
      let(:producer) { create(:supplier_enterprise) }
      let(:oc) { create(:simple_order_cycle, coordinator: coordinator) }

      context "when no order_cycle or coordinator are provided for reference" do
        it "returns an empty scope" do
          expect(permissions.order_cycle_enterprises_for()).to be_empty
        end
      end

      context "as a manager of the coordinator" do
        it "returns the coordinator itself" do
          permissions.stub(:managed_enterprises) { Enterprise.where(id: [coordinator]) }
          expect(permissions.order_cycle_enterprises_for(order_cycle: oc)).to include coordinator
        end

        context "where P-OC has been granted to the coordinator by other enterprises" do
          before do
            create(:enterprise_relationship, parent: hub, child: coordinator, permissions_list: [:add_to_order_cycle])
            permissions.stub(:managed_enterprises) { Enterprise.where(id: [coordinator]) }
          end

          context "where the coordinator sells own" do
            it "returns enterprises which have granted P-OC to the coordinator" do
              enterprises = permissions.order_cycle_enterprises_for(order_cycle: oc)
              expect(enterprises).to include hub
              expect(enterprises).to_not include producer
            end
          end

          context "where the coordinator sells 'own'" do
            before { coordinator.stub(:sells) { 'own' } }
            it "returns just the coordinator" do
              enterprises = permissions.order_cycle_enterprises_for(order_cycle: oc)
              expect(enterprises).to_not include hub, producer
            end
          end
        end
      end

      context "as a manager of a hub that has granted P-OC to the coordinator" do
        before do
          permissions.stub(:managed_enterprises) { Enterprise.where(id: [hub]) }
        end

        context "that has granted P-OC to the coordinator" do
          before do
            create(:enterprise_relationship, parent: hub, child: coordinator, permissions_list: [:add_to_order_cycle])
          end

          it "returns my hub" do
            enterprises = permissions.order_cycle_enterprises_for(order_cycle: oc)
            expect(enterprises).to include hub
            expect(enterprises).to_not include producer, coordinator
          end

          context "and has also granted P-OC to a producer" do
            before do
              create(:enterprise_relationship, parent: hub, child: producer, permissions_list: [:add_to_order_cycle])
            end
            it "does not return that producer" do
              enterprises = permissions.order_cycle_enterprises_for(order_cycle: oc)
              expect(enterprises).to_not include producer
            end
          end
        end

        context "that has not granted P-OC to the coordinator" do
          it "does not return my hub" do
            enterprises = permissions.order_cycle_enterprises_for(order_cycle: oc)
            expect(enterprises).to_not include hub, producer, coordinator
          end

          context "but is already in the order cycle" do
            let!(:ex) { create(:exchange, order_cycle: oc, sender: coordinator, receiver: hub, incoming: false) }

            it "returns my hub" do
              enterprises = permissions.order_cycle_enterprises_for(order_cycle: oc)
              expect(enterprises).to include hub
              expect(enterprises).to_not include producer, coordinator
            end
          end
        end
      end

      context "as a manager of a producer" do
        before do
          permissions.stub(:managed_enterprises) { Enterprise.where(id: [producer]) }
        end

        context "which has granted P-OC to the coordinator" do
          before do
            create(:enterprise_relationship, parent: producer, child: coordinator, permissions_list: [:add_to_order_cycle])
          end

          it "returns my producer, and the coordindator itself" do
            enterprises = permissions.order_cycle_enterprises_for(order_cycle: oc)
            expect(enterprises).to include producer, coordinator
            expect(enterprises).to_not include hub
          end

          context "and has also granted P-OC to a hub" do
            before do
              create(:enterprise_relationship, parent: producer, child: hub, permissions_list: [:add_to_order_cycle])
            end

            it "returns that hub as well" do
              enterprises = permissions.order_cycle_enterprises_for(order_cycle: oc)
              expect(enterprises).to include producer, coordinator, hub
            end
          end
        end

        context "which has not granted P-OC to the coordinator" do
          it "does not return my producer" do
            enterprises = permissions.order_cycle_enterprises_for(order_cycle: oc)
            expect(enterprises).to_not include producer
          end

          context "but is already in the order cycle" do
            let!(:ex_incoming) { create(:exchange, order_cycle: oc, sender: producer, receiver: coordinator, incoming: true) }

            # TODO: update this when we are confident about P-OCs
            it "returns my producer" do
              enterprises = permissions.order_cycle_enterprises_for(order_cycle: oc)
              expect(enterprises).to include producer
              expect(enterprises).to_not include hub, coordinator
            end

            context "and has variants distributed by an outgoing hub" do
              let!(:ex_outgoing) { create(:exchange, order_cycle: oc, sender: coordinator, receiver: hub, incoming: false) }
              before { ex_outgoing.variants << create(:variant, product: create(:product, supplier: producer)) }

              # TODO: update this when we are confident about P-OCs
              it "returns that hub as well" do
                enterprises = permissions.order_cycle_enterprises_for(order_cycle: oc)
                expect(enterprises).to include producer, hub
                expect(enterprises).to_not include coordinator
              end
            end
          end
        end
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

    describe "finding exchanges of an order cycle that an admin can manage" do
      let(:oc) { create(:simple_order_cycle) }
      let!(:ex) { create(:exchange, order_cycle: oc, sender: e1, receiver: e2) }

      before do
        permissions.stub(:managed_enterprises) { Enterprise.where('1=0') }
        permissions.stub(:related_enterprises_with) { Enterprise.where('1=0') }
      end

      it "returns exchanges involving enterprises managed by the user" do
        permissions.stub(:managed_enterprises) { Enterprise.where(id: [e1, e2]) }
        permissions.order_cycle_exchanges(oc).should == [ex]
      end

      it "does not return exchanges involving enterprises with E2E permission" do
        permissions.stub(:related_enterprises_with) { Enterprise.where(id: [e1, e2]) }
        permissions.order_cycle_exchanges(oc).should == []
      end

      it "returns exchanges involving only the sender" do
        permissions.stub(:managed_enterprises) { Enterprise.where(id: [e1]) }
        permissions.order_cycle_exchanges(oc).should == [ex]
      end

      it "returns exchanges involving only the receiver" do
        permissions.stub(:managed_enterprises) { Enterprise.where(id: [e2]) }
        permissions.order_cycle_exchanges(oc).should == [ex]
      end

      describe "special permissions for managers of producers" do
        let!(:producer) { create(:supplier_enterprise) }
        before do
          ex.incoming = false
          ex.save
        end

        it "returns outgoing exchanges where the hub has been granted P-OC by a supplier I manage" do
          permissions.stub(:managed_enterprises) { Enterprise.where(id: [producer]) }
          create(:enterprise_relationship, parent: producer, child: e2, permissions_list: [:add_to_order_cycle])

          permissions.order_cycle_exchanges(oc).should == [ex]
        end


        it "does not return outgoing exchanges where only the coordinator has been granted P-OC by a producer I manage" do
          permissions.stub(:managed_enterprises) { Enterprise.where(id: [producer]) }
          create(:enterprise_relationship, parent: producer, child: e1, permissions_list: [:add_to_order_cycle])

          permissions.order_cycle_exchanges(oc).should == []
        end

        # TODO: this is testing legacy behaviour for backwards compatability, remove when behaviour no longer required
        it "returns outgoing exchanges which include variants produced by a producer I manage" do
          product = create(:product, supplier: producer)
          variant = create(:variant, product: product)
          ex.variants << variant
          permissions.stub(:managed_enterprises) { Enterprise.where(id: [producer]) }

          permissions.order_cycle_exchanges(oc).should == [ex]
        end
      end
    end

    describe "finding the variants within a given exchange which are visible to a user" do
      let!(:producer1) { create(:supplier_enterprise) }
      let!(:producer2) { create(:supplier_enterprise) }
      let!(:v1) { create(:variant, product: create(:simple_product, supplier: producer1)) }
      let!(:v2) { create(:variant, product: create(:simple_product, supplier: producer2)) }
      let(:oc) { create(:simple_order_cycle) }

      describe "incoming exchanges" do
        let!(:ex) { create(:exchange, order_cycle: oc, sender: producer1, receiver: e1, incoming: true) }

        context "as a manager of the coordinator" do
          before do
            permissions.stub(:managed_enterprises) { Enterprise.where(id: [e1]) }
          end

          it "returns all variants belonging to the sending producer" do
            visible = permissions.visible_variants_within(ex)
            expect(visible).to include v1
            expect(visible).to_not include v2
          end
        end

        context "as a manager of the producer" do
          before do
            permissions.stub(:managed_enterprises) { Enterprise.where(id: [producer1]) }
          end

          it "returns all variants belonging to the sending producer" do
            visible = permissions.visible_variants_within(ex)
            expect(visible).to include v1
            expect(visible).to_not include v2
          end
        end

        context "as a manager of a hub which has been granted P-OC by the producer" do
          before do
            permissions.stub(:managed_enterprises) { Enterprise.where(id: [e2]) }
            create(:enterprise_relationship, parent: producer1, child: e2, permissions_list: [:add_to_order_cycle])
          end

          it "returns no variants" do
            visible = permissions.visible_variants_within(ex)
            expect(visible).to eq []
          end
        end
      end

      describe "outgoing exchanges" do
        let!(:ex) { create(:exchange, order_cycle: oc, sender: e1, receiver: e2, incoming: false) }

        context "as a manager of the coordinator" do
          before do
            permissions.stub(:managed_enterprises) { Enterprise.where(id: [e1]) }
            create(:enterprise_relationship, parent: producer1, child: e2, permissions_list: [:add_to_order_cycle])
          end

          it "returns all variants of any producer which has granted the outgoing hub P-OC" do
            visible = permissions.visible_variants_within(ex)
            expect(visible).to include v1
            expect(visible).to_not include v2
          end
        end

        context "as manager of the outgoing hub" do
          before do
            permissions.stub(:managed_enterprises) { Enterprise.where(id: [e2]) }
            create(:enterprise_relationship, parent: producer1, child: e2, permissions_list: [:add_to_order_cycle])
          end

          it "returns all variants of any producer which has granted the outgoing hub P-OC" do
            visible = permissions.visible_variants_within(ex)
            expect(visible).to include v1
            expect(visible).to_not include v2
          end
        end

        context "as the manager of a producer which has granted P-OC to the outgoing hub" do
          before do
            permissions.stub(:managed_enterprises) { Enterprise.where(id: [producer1]) }
            create(:enterprise_relationship, parent: producer1, child: e2, permissions_list: [:add_to_order_cycle])
          end

          it "returns all of my produced variants" do
            visible = permissions.visible_variants_within(ex)
            expect(visible).to include v1
            expect(visible).to_not include v2
          end
        end

        context "as the manager of a producer which has not granted P-OC to the outgoing hub" do
          before do
            permissions.stub(:managed_enterprises) { Enterprise.where(id: [producer2]) }
            create(:enterprise_relationship, parent: producer1, child: e2, permissions_list: [:add_to_order_cycle])
          end

          it "returns an empty array" do
            expect(permissions.visible_variants_within(ex)).to eq []
          end
        end

        # TODO: for backwards compatability, remove later
        context "as the manager of a producer which has not granted P-OC to the outgoing hub, but which has variants already in the exchange" do
          # This one won't be in the exchange, and so shouldn't be visible
          let!(:v3) { create(:variant, product: create(:simple_product, supplier: producer2)) }

          before do
            permissions.stub(:managed_enterprises) { Enterprise.where(id: [producer2]) }
            create(:enterprise_relationship, parent: producer1, child: e2, permissions_list: [:add_to_order_cycle])
            ex.variants << v2
          end

          it "returns those variants that are in the exchange" do
            visible = permissions.visible_variants_within(ex)
            expect(visible).to_not include v1, v3
            expect(visible).to include v2
          end
        end
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
  end
end
