require 'spec_helper'

module Spree
  describe Product do

    describe "associations" do
      it { should belong_to(:supplier) }
      it { should belong_to(:primary_taxon) }
      it { should have_many(:product_distributions) }
    end

    describe "validations and defaults" do
      it "is valid when created from factory" do
        create(:product).should be_valid
      end

      it "requires a primary taxon" do
        product = create(:simple_product)
        product.taxons = []
        product.primary_taxon = nil
        product.should_not be_valid
      end

      it "requires a supplier" do
        product = create(:simple_product)
        product.supplier = nil
        product.should_not be_valid
      end

      it "should default available_on to now" do
        Timecop.freeze
        product = Product.new
        product.available_on.should == Time.now
      end

      context "when the product has variants" do
        let(:product) do
          product = create(:simple_product)
          create(:variant, product: product)
          product.reload
        end

        it "requires a unit" do
          product.variant_unit = nil
          product.should_not be_valid
        end

        %w(weight volume).each do |unit|
          context "when unit is #{unit}" do
            it "is valid when unit scale is set and unit name is not" do
              product.variant_unit = unit
              product.variant_unit_scale = 1
              product.variant_unit_name = nil
              product.should be_valid
            end

            it "is invalid when unit scale is not set" do
              product.variant_unit = unit
              product.variant_unit_scale = nil
              product.variant_unit_name = nil
              product.should_not be_valid
            end
          end
        end

        context "when the unit is items" do
          it "is valid when unit name is set and unit scale is not" do
            product.variant_unit = 'items'
            product.variant_unit_name = 'loaf'
            product.variant_unit_scale = nil
            product.should be_valid
          end

          it "is invalid when unit name is not set" do
            product.variant_unit = 'items'
            product.variant_unit_name = nil
            product.variant_unit_scale = nil
            product.should_not be_valid
          end
        end
      end

      context "when product does not have variants" do
        let(:product) { create(:simple_product) }

        it "does not require any variant unit fields" do
          product.variant_unit = nil
          product.variant_unit_name = nil
          product.variant_unit_scale = nil

          product.should be_valid
        end

        it "requires a unit scale when variant unit is weight" do
          product.variant_unit = 'weight'
          product.variant_unit_scale = nil
          product.variant_unit_name = nil

          product.should_not be_valid
        end
      end
    end
    

    describe "scopes" do
      describe "in_supplier" do
        it "shows products in supplier" do
          s1 = create(:supplier_enterprise)
          s2 = create(:supplier_enterprise)
          p1 = create(:product, supplier: s1)
          p2 = create(:product, supplier: s2)
          Product.in_supplier(s1).should == [p1]
        end
      end

      describe "in_distributor" do
        it "shows products in product distribution" do
          d1 = create(:distributor_enterprise)
          d2 = create(:distributor_enterprise)
          p1 = create(:product, distributors: [d1])
          p2 = create(:product, distributors: [d2])
          Product.in_distributor(d1).should == [p1]
        end

        it "shows products in order cycle distribution" do
          s = create(:supplier_enterprise)
          d1 = create(:distributor_enterprise)
          d2 = create(:distributor_enterprise)
          p1 = create(:product)
          p2 = create(:product)
          create(:simple_order_cycle, suppliers: [s], distributors: [d1], variants: [p1.master])
          create(:simple_order_cycle, suppliers: [s], distributors: [d2], variants: [p2.master])
          Product.in_distributor(d1).should == [p1]
        end

        it "shows products in order cycle distribution by variant" do
          s = create(:supplier_enterprise)
          d1 = create(:distributor_enterprise)
          d2 = create(:distributor_enterprise)
          p1 = create(:product)
          v1 = create(:variant, product: p1)
          p2 = create(:product)
          v2 = create(:variant, product: p2)
          create(:simple_order_cycle, suppliers: [s], distributors: [d1], variants: [v1])
          create(:simple_order_cycle, suppliers: [s], distributors: [d2], variants: [v2])
          Product.in_distributor(d1).should == [p1]
        end

        it "doesn't show products listed in the incoming exchange only", :future => true do
          s = create(:supplier_enterprise)
          c = create(:distributor_enterprise)
          d = create(:distributor_enterprise)
          p = create(:product)
          oc = create(:simple_order_cycle, coordinator: c, suppliers: [s], distributors: [d])
          ex = oc.exchanges.incoming.first
          ex.variants << p.master

          Product.in_distributor(d).should be_empty
        end

        it "shows products in both without duplicates" do
          s = create(:supplier_enterprise)
          d = create(:distributor_enterprise)
          p = create(:product, distributors: [d])
          create(:simple_order_cycle, suppliers: [s], distributors: [d], variants: [p.master])
          Product.in_distributor(d).should == [p]
        end
      end

      describe "in_product_distribution_by" do
        it "shows products in product distribution" do
          d1 = create(:distributor_enterprise)
          d2 = create(:distributor_enterprise)
          p1 = create(:product, distributors: [d1])
          p2 = create(:product, distributors: [d2])
          Product.in_product_distribution_by(d1).should == [p1]
        end

        it "does not show products in order cycle distribution" do
          s = create(:supplier_enterprise)
          d1 = create(:distributor_enterprise)
          d2 = create(:distributor_enterprise)
          p1 = create(:product)
          p2 = create(:product)
          create(:simple_order_cycle, suppliers: [s], distributors: [d1], variants: [p1.master])
          create(:simple_order_cycle, suppliers: [s], distributors: [d2], variants: [p2.master])
          Product.in_product_distribution_by(d1).should == []
        end
      end

      describe "in_supplier_or_distributor" do
        it "shows products in supplier" do
          s1 = create(:supplier_enterprise)
          s2 = create(:supplier_enterprise)
          p1 = create(:product, supplier: s1)
          p2 = create(:product, supplier: s2)
          Product.in_supplier_or_distributor(s1).should == [p1]
        end

        it "shows products in product distribution" do
          d1 = create(:distributor_enterprise)
          d2 = create(:distributor_enterprise)
          p1 = create(:product, distributors: [d1])
          p2 = create(:product, distributors: [d2])
          Product.in_supplier_or_distributor(d1).should == [p1]
        end

        it "shows products in order cycle distribution" do
          s = create(:supplier_enterprise)
          d1 = create(:distributor_enterprise)
          d2 = create(:distributor_enterprise)
          p1 = create(:product)
          p2 = create(:product)
          create(:simple_order_cycle, suppliers: [s], distributors: [d1], variants: [p1.master])
          create(:simple_order_cycle, suppliers: [s], distributors: [d2], variants: [p2.master])
          Product.in_supplier_or_distributor(d1).should == [p1]
        end

        it "shows products in all three without duplicates" do
          s = create(:supplier_enterprise)
          d = create(:distributor_enterprise)
          p = create(:product, supplier: s, distributors: [d])
          create(:simple_order_cycle, suppliers: [s], distributors: [d], variants: [p.master])
          [s, d].each { |e| Product.in_supplier_or_distributor(e).should == [p] }
        end
      end

      describe "in_order_cycle" do
        it "shows products in order cycle distribution" do
          s = create(:supplier_enterprise)
          d1 = create(:distributor_enterprise)
          d2 = create(:distributor_enterprise)
          p1 = create(:product)
          p2 = create(:product)
          oc1 = create(:simple_order_cycle, suppliers: [s], distributors: [d1], variants: [p1.master])
          oc2 = create(:simple_order_cycle, suppliers: [s], distributors: [d2], variants: [p2.master])
          Product.in_order_cycle(oc1).should == [p1]
        end
      end

      describe "in_an_active_order_cycle" do
        it "shows products in order cycle distribution" do
          s = create(:supplier_enterprise)
          d2 = create(:distributor_enterprise)
          d3 = create(:distributor_enterprise)
          p1 = create(:product)
          p2 = create(:product)
          p3 = create(:product)
          oc2 = create(:simple_order_cycle, suppliers: [s], distributors: [d2], variants: [p2.master], orders_close_at: 1.day.ago)
          oc2 = create(:simple_order_cycle, suppliers: [s], distributors: [d3], variants: [p3.master], orders_close_at: Date.tomorrow)
          Product.in_an_active_order_cycle.should == [p3]
        end
      end

      describe "access roles" do
        before(:each) do
          @e1 = create(:enterprise)
          @e2 = create(:enterprise)
          @p1 = create(:product, supplier: @e1)
          @p2 = create(:product, supplier: @e2)
        end

        it "shows only products for given user" do
          user = create(:user)
          user.spree_roles = []
          @e1.enterprise_roles.build(user: user).save

          product = Product.managed_by user
          product.count.should == 1
          product.should include @p1
        end

        it "shows all products for admin user" do
          user = create(:admin_user)

          product = Product.managed_by user
          product.count.should == 2
          product.should include @p1
          product.should include @p2
        end
      end
    end

    describe "finders" do
      it "finds the product distribution for a particular distributor" do
        distributor = create(:distributor_enterprise)
        product = create(:product)
        product_distribution = create(:product_distribution, product: product, distributor: distributor)
        product.product_distribution_for(distributor).should == product_distribution
      end
    end

    describe "membership" do
      it "queries its membership of a particular product distribution" do
        d1 = create(:distributor_enterprise)
        d2 = create(:distributor_enterprise)
        p = create(:product, distributors: [d1])

        p.should be_in_distributor d1
        p.should_not be_in_distributor d2
      end

      it "queries its membership of a particular order cycle distribution" do
        d1 = create(:distributor_enterprise)
        d2 = create(:distributor_enterprise)
        p1 = create(:product)
        p2 = create(:product)
        oc1 = create(:order_cycle, :distributors => [d1], :variants => [p1.master])
        oc2 = create(:order_cycle, :distributors => [d2], :variants => [p2.master])

        p1.should be_in_distributor d1
        p1.should_not be_in_distributor d2
      end

      it "queries its membership of a particular order cycle" do
        d1 = create(:distributor_enterprise)
        d2 = create(:distributor_enterprise)
        p1 = create(:product)
        p2 = create(:product)
        oc1 = create(:order_cycle, :distributors => [d1], :variants => [p1.master])
        oc2 = create(:order_cycle, :distributors => [d2], :variants => [p2.master])

        p1.should be_in_order_cycle oc1
        p1.should_not be_in_order_cycle oc2
      end
    end

    describe "finding variants for an order cycle and hub" do
      let(:oc) { create(:simple_order_cycle) }
      let(:s) { create(:supplier_enterprise) }
      let(:d1) { create(:distributor_enterprise) }
      let(:d2) { create(:distributor_enterprise) }

      let(:p1) { create(:simple_product) }
      let(:p2) { create(:simple_product) }
      let(:v1) { create(:variant, product: p1) }
      let(:v2) { create(:variant, product: p2) }

      let(:p_external) { create(:simple_product) }
      let(:v_external) { create(:variant, product: p_external) }

      let!(:ex_in) { create(:exchange, order_cycle: oc, sender: s, receiver: oc.coordinator,
                            incoming: true, variants: [v1, v2]) }
      let!(:ex_out1) { create(:exchange, order_cycle: oc, sender: oc.coordinator, receiver: d1,
                              incoming: false, variants: [v1]) }
      let!(:ex_out2) { create(:exchange, order_cycle: oc, sender: oc.coordinator, receiver: d2,
                              incoming: false, variants: [v2]) }

      it "returns variants in the order cycle and distributor" do
        p1.variants_for(oc, d1).should == [v1]
        p2.variants_for(oc, d2).should == [v2]
      end

      it "does not return variants in the order cycle but not the distributor" do
        p1.variants_for(oc, d2).should be_empty
        p2.variants_for(oc, d1).should be_empty
      end

      it "does not return variants not in the order cycle" do
        p_external.variants_for(oc, d1).should be_empty
      end
    end

    describe "variant units" do
      context "when the product initially has no variant unit" do
        let!(:p) { create(:simple_product,
                          variant_unit: nil,
                          variant_unit_scale: nil,
                          variant_unit_name: nil) }

        context "when the required option type does not exist" do
          it "creates the option type and assigns it to the product" do
            expect {
              p.update_attributes!(variant_unit: 'weight', variant_unit_scale: 1000)
            }.to change(Spree::OptionType, :count).by(1)

            ot = Spree::OptionType.last
            ot.name.should == 'unit_weight'
            ot.presentation.should == 'Weight'

            p.option_types.should == [ot]
          end

          it "does the same with volume" do
            expect {
              p.update_attributes!(variant_unit: 'volume', variant_unit_scale: 1000)
            }.to change(Spree::OptionType, :count).by(1)

            ot = Spree::OptionType.last
            ot.name.should == 'unit_volume'
            ot.presentation.should == 'Volume'

            p.option_types.should == [ot]
          end

          it "does the same with items" do
            expect {
              p.update_attributes!(variant_unit: 'items', variant_unit_name: 'packet')
            }.to change(Spree::OptionType, :count).by(1)

            ot = Spree::OptionType.last
            ot.name.should == 'unit_items'
            ot.presentation.should == 'Items'

            p.option_types.should == [ot]
          end
        end

        context "when the required option type already exists" do
          let!(:ot) { create(:option_type, name: 'unit_weight', presentation: 'Weight') }

          it "looks up the option type and assigns it to the product" do
            expect {
              p.update_attributes!(variant_unit: 'weight', variant_unit_scale: 1000)
            }.to change(Spree::OptionType, :count).by(0)

            p.option_types.should == [ot]
          end
        end
      end

      context "when the product already has a variant unit set (and all required option types exist)" do
        let!(:p) { create(:simple_product,
                          variant_unit: 'weight',
                          variant_unit_scale: 1,
                          variant_unit_name: nil) }

        let!(:ot_volume) { create(:option_type, name: 'unit_volume', presentation: 'Volume') }

        it "removes the old option type and assigns the new one" do
          p.update_attributes!(variant_unit: 'volume', variant_unit_scale: 0.001)
          p.option_types.should == [ot_volume]
        end

        it "leaves option type unassigned if none is provided" do
          p.update_attributes!(variant_unit: nil, variant_unit_scale: nil)
          p.option_types.should == []
        end

        it "does not remove and re-add the option type if it is not changed" do
          p.option_types.should_receive(:delete).never
          p.update_attributes!(name: 'foo')
        end

        it "removes the related option values from all its variants" do
          ot = Spree::OptionType.find_by_name 'unit_weight'
          v = create(:variant, product: p)
          p.reload

          expect {
            p.update_attributes!(variant_unit: 'volume', variant_unit_scale: 0.001)
          }.to change(v.option_values(true), :count).by(-1)
        end

        it "removes the related option values from its master variant" do
          ot = Spree::OptionType.find_by_name 'unit_weight'
          p.master.update_attributes!(unit_value: 1)
          p.reload

          expect {
            p.update_attributes!(variant_unit: 'volume', variant_unit_scale: 0.001)
          }.to change(p.master.option_values(true), :count).by(-1)
        end
      end

      describe "returning the variant unit option type" do
        it "returns nil when variant_unit is not set" do
          p = create(:simple_product, variant_unit: nil)
          p.variant_unit_option_type.should be_nil
        end
      end

      it "finds all variant unit option types" do
        ot1 = create(:option_type, name: 'unit_weight', presentation: 'Weight')
        ot2 = create(:option_type, name: 'unit_volume', presentation: 'Volume')
        ot3 = create(:option_type, name: 'unit_items', presentation: 'Items')
        ot4 = create(:option_type, name: 'foo_unit_bar', presentation: 'Foo')

        Spree::Product.all_variant_unit_option_types.sort.should == [ot1, ot2, ot3].sort
      end
    end

    describe "option types" do
      describe "removing an option type" do
        it "removes the associated option values from all variants" do
          # Given a product with a variant unit option type and values
          p = create(:simple_product, variant_unit: 'weight', variant_unit_scale: 1)
          v1 = create(:variant, product: p, unit_value: 100, option_values: [])
          v2 = create(:variant, product: p, unit_value: 200, option_values: [])

          # And a custom option type and values
          ot = create(:option_type, name: 'foo', presentation: 'foo')
          p.option_types << ot
          ov1 = create(:option_value, option_type: ot, name: 'One', presentation: 'One')
          ov2 = create(:option_value, option_type: ot, name: 'Two', presentation: 'Two')
          v1.option_values << ov1
          v2.option_values << ov2

          # When we remove the custom option type
          p.option_type_ids = p.option_type_ids.reject { |id| id == ot.id }

          # Then the associated option values should have been removed from the variants
          v1.option_values(true).should_not include ov1
          v2.option_values(true).should_not include ov2

          # And the option values themselves should still exist
          Spree::OptionValue.where(id: [ov1.id, ov2.id]).count.should == 2
        end
      end
    end

    describe "stock filtering" do
      it "considers products that are on_demand as being in stock" do
        product = create(:simple_product, on_demand: true)
        product.master.update_attribute(:count_on_hand, 0)
        product.has_stock?.should == true
      end

      describe "finding products in stock for a particular distribution" do
        it "returns in-stock products without variants" do
          p = create(:simple_product)
          p.master.update_attribute(:count_on_hand, 1)
          d = create(:distributor_enterprise)
          oc = create(:simple_order_cycle, distributors: [d])
          oc.exchanges.outgoing.first.variants << p.master

          p.should have_stock_for_distribution(oc, d)
        end

        it "returns on-demand products" do
          p = create(:simple_product, on_demand: true)
          p.master.update_attribute(:count_on_hand, 0)
          d = create(:distributor_enterprise)
          oc = create(:simple_order_cycle, distributors: [d])
          oc.exchanges.outgoing.first.variants << p.master

          p.should have_stock_for_distribution(oc, d)
        end

        it "returns products with in-stock variants" do
          p = create(:simple_product)
          v = create(:variant, product: p)
          v.update_attribute(:count_on_hand, 1)
          d = create(:distributor_enterprise)
          oc = create(:simple_order_cycle, distributors: [d])
          oc.exchanges.outgoing.first.variants << v

          p.should have_stock_for_distribution(oc, d)
        end

        it "returns products with on-demand variants" do
          p = create(:simple_product)
          v = create(:variant, product: p, on_demand: true)
          v.update_attribute(:count_on_hand, 0)
          d = create(:distributor_enterprise)
          oc = create(:simple_order_cycle, distributors: [d])
          oc.exchanges.outgoing.first.variants << v

          p.should have_stock_for_distribution(oc, d)
        end

        it "does not return products that have stock not in the distribution" do
          p = create(:simple_product)
          p.master.update_attribute(:count_on_hand, 1)
          d = create(:distributor_enterprise)
          oc = create(:simple_order_cycle, distributors: [d])

          p.should_not have_stock_for_distribution(oc, d)
        end
      end
    end

    describe "Taxons" do
      let(:taxon1) { create(:taxon) }
      let(:taxon2) { create(:taxon) }
      let(:product) { create(:simple_product) }

      it "returns the first taxon as the primary taxon" do
        product.taxons.should == [product.primary_taxon]
      end
    end

  end
end
