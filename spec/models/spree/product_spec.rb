require 'spec_helper'

module Spree
  describe Product do

    describe "associations" do
      it { should belong_to(:supplier) }
      it { should belong_to(:primary_taxon) }
      it { should have_many(:product_distributions) }
    end

    describe "validations and defaults" do
      it "is valid when built from factory" do
        build(:product).should be_valid
      end

      it "requires a primary taxon" do
        build(:simple_product, taxons: [], primary_taxon: nil).should_not be_valid
      end

      it "requires a supplier" do
        build(:simple_product, supplier: nil).should_not be_valid
      end

      it "does not save when master is invalid" do
        s = create(:supplier_enterprise)
        t = create(:taxon)
        product = Product.new supplier_id: s.id, name: "Apples", price: 1, primary_taxon_id: t.id, variant_unit: "weight", variant_unit_scale: 1000, unit_value: 1
        product.on_hand = "10,000"
        expect(product.save).to be false

        expect(product.errors[:count_on_hand]).to include "is not a number"
      end

      it "defaults available_on to now" do
        Timecop.freeze do
          product = Product.new
          product.available_on.should == Time.zone.now
        end
      end

      describe "tax category" do
        context "when a tax category is required" do
          it "is invalid when a tax category is not provided" do
            with_products_require_tax_category(true) do
              build(:product, tax_category_id: nil).should_not be_valid
            end
          end
        end

        context "when a tax category is not required" do
          it "is valid when a tax category is not provided" do
            with_products_require_tax_category(false) do
              build(:product, tax_category_id: nil).should be_valid
            end
          end
        end
      end


      it "does not allow the last variant to be deleted" do
        product = create(:simple_product)
        expect(product.variants(:reload).length).to eq 1
        v = product.variants.last
        v.delete
        expect(v.errors[:product]).to include "must have at least one variant"
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

        context "saving a new product" do
          let!(:product){ Spree::Product.new }

          before do
            product.primary_taxon = create(:taxon)
            product.supplier = create(:supplier_enterprise)
            product.name = "Product1"
            product.variant_unit = "weight"
            product.variant_unit_scale = 1000
            product.unit_value = 1
            product.on_hand = 3
            product.price = 4.27
            product.save!
          end

          it "copies the properties on master variant to the first standard variant" do
            expect(product.variants(:reload).length).to eq 1
            standard_variant = product.variants(:reload).first
            expect(standard_variant.price).to eq product.master.price
          end

          it "only duplicates master with after_save when no standard variants exist" do
            expect(product).to receive :ensure_standard_variant
            product.name = "Something else"
            expect{product.save!}.to_not change{product.variants.count}
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

      context "a basic product" do
        let(:product) { create(:simple_product) }

        it "requires variant unit fields" do
          product.variant_unit = nil
          product.variant_unit_name = nil
          product.variant_unit_scale = nil

          expect(product).to be_invalid
        end

        it "requires a unit scale when variant unit is weight" do
          product.variant_unit = 'weight'
          product.variant_unit_scale = nil
          product.variant_unit_name = nil

          product.should_not be_valid
        end
      end
    end

    describe "callbacks" do
      let(:product) { create(:simple_product) }

      it "refreshes the products cache on save" do
        expect(OpenFoodNetwork::ProductsCache).to receive(:product_changed).with(product)
        product.name = 'asdf'
        product.save
      end

      it "refreshes the products cache on delete" do
        expect(OpenFoodNetwork::ProductsCache).to receive(:product_deleted).with(product)
        product.delete
      end

      # On destroy, all distributed variants are refreshed by a Variant around_destroy
      # callback, so we don't need to do anything on the product model.

      describe "touching affected enterprises when the product is deleted" do
        let(:product) { create(:simple_product) }
        let(:supplier) { product.supplier }
        let(:distributor) { create(:distributor_enterprise) }
        let!(:oc) { create(:simple_order_cycle, distributors: [distributor], variants: [product.variants.first]) }

        it "touches the supplier" do
          expect { product.delete }.to change { supplier.reload.updated_at }
        end

        it "touches all distributors" do
          expect { product.delete }.to change { distributor.reload.updated_at }
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

        it "doesn't show products listed in the incoming exchange only" do
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

      describe "visible_for" do
        let(:enterprise) { create(:distributor_enterprise) }
        let!(:new_variant) { create(:variant) }
        let!(:hidden_variant) { create(:variant) }
        let!(:visible_variant) { create(:variant) }
        let!(:hidden_inventory_item) { create(:inventory_item, enterprise: enterprise, variant: hidden_variant, visible: false ) }
        let!(:visible_inventory_item) { create(:inventory_item, enterprise: enterprise, variant: visible_variant, visible: true ) }

        let!(:products) { Spree::Product.visible_for(enterprise) }

        it "lists any products with variants that are listed as visible=true" do
          expect(products).to include visible_variant.product
          expect(products).to_not include new_variant.product, hidden_variant.product
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

    describe "properties" do
      it "returns product properties as a hash" do
        product = create(:simple_product)
        product.set_property 'Organic Certified', 'NASAA 12345'
        property = product.properties.last

        product.properties_including_inherited.should == [{id: property.id, name: "Organic Certified", value: 'NASAA 12345'}]
      end

      it "returns producer properties as a hash" do
        supplier = create(:supplier_enterprise)
        product = create(:simple_product, supplier: supplier)

        supplier.set_producer_property 'Organic Certified', 'NASAA 54321'
        property = supplier.properties.last

        product.properties_including_inherited.should == [{id: property.id, name: "Organic Certified", value: 'NASAA 54321'}]
      end

      it "overrides producer properties with product properties" do
        supplier = create(:supplier_enterprise)
        product = create(:simple_product, supplier: supplier)

        product.set_property 'Organic Certified', 'NASAA 12345'
        supplier.set_producer_property 'Organic Certified', 'NASAA 54321'
        property = product.properties.last

        product.properties_including_inherited.should == [{id: property.id, name: "Organic Certified", value: 'NASAA 12345'}]
      end

      context "when product has an inherit_properties value set to true" do
        let(:supplier) { create(:supplier_enterprise) }
        let(:product) { create(:simple_product, supplier: supplier, inherits_properties: true) }

        it "inherits producer properties" do
          supplier.set_producer_property 'Organic Certified', 'NASAA 54321'
          property = supplier.properties.last

          product.properties_including_inherited.should == [{id: property.id, name: "Organic Certified", value: 'NASAA 54321'}]
        end
      end

      context "when product has an inherit_properties value set to false" do
        let(:supplier) { create(:supplier_enterprise) }
        let(:product) { create(:simple_product, supplier: supplier, inherits_properties: false) }

        it "does not inherit producer properties" do
          supplier.set_producer_property 'Organic Certified', 'NASAA 54321'

          product.properties_including_inherited.should == []
        end
      end

      it "sorts by position" do
        supplier = create(:supplier_enterprise)
        product = create(:simple_product, supplier: supplier)

        pa = Spree::Property.create! name: 'A', presentation: 'A'
        pb = Spree::Property.create! name: 'B', presentation: 'B'
        pc = Spree::Property.create! name: 'C', presentation: 'C'

        product.product_properties.create!({property_id: pa.id, value: '1', position: 1}, {without_protection: true})
        product.product_properties.create!({property_id: pc.id, value: '3', position: 3}, {without_protection: true})
        supplier.producer_properties.create!({property_id: pb.id, value: '2', position: 2}, {without_protection: true})

        product.properties_including_inherited.should ==
          [{id: pa.id, name: "A", value: '1'},
           {id: pb.id, name: "B", value: '2'},
           {id: pc.id, name: "C", value: '3'}]
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
        oc1 = create(:simple_order_cycle, :distributors => [d1], :variants => [p1.master])
        oc2 = create(:simple_order_cycle, :distributors => [d2], :variants => [p2.master])

        p1.should be_in_distributor d1
        p1.should_not be_in_distributor d2
      end

      it "queries its membership of a particular order cycle" do
        d1 = create(:distributor_enterprise)
        d2 = create(:distributor_enterprise)
        p1 = create(:product)
        p2 = create(:product)
        oc1 = create(:simple_order_cycle, :distributors => [d1], :variants => [p1.master])
        oc2 = create(:simple_order_cycle, :distributors => [d2], :variants => [p2.master])

        p1.should be_in_order_cycle oc1
        p1.should_not be_in_order_cycle oc2
      end
    end


    describe "variant units" do
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

        it "does not remove and re-add the option type if it is not changed" do
          p.option_types.should_receive(:delete).never
          p.update_attributes!(name: 'foo')
        end

        it "removes the related option values from all its variants and replaces them" do
          ot = Spree::OptionType.find_by_name 'unit_weight'
          v = create(:variant, unit_value: 1, product: p)
          p.reload

          v.option_values.map(&:name).include?("1L").should == false
          v.option_values.map(&:name).include?("1g").should == true
                    expect {
            p.update_attributes!(variant_unit: 'volume', variant_unit_scale: 0.001)
          }.to change(p.master.option_values(true), :count).by(0)
          v.reload
          v.option_values.map(&:name).include?("1L").should == true
          v.option_values.map(&:name).include?("1g").should == false
        end

        it "removes the related option values from its master variant and replaces them" do
          ot = Spree::OptionType.find_by_name 'unit_weight'
          p.master.update_attributes!(unit_value: 1)
          p.reload

          p.master.option_values.map(&:name).include?("1L").should == false
          p.master.option_values.map(&:name).include?("1g").should == true
                    expect {
            p.update_attributes!(variant_unit: 'volume', variant_unit_scale: 0.001)
          }.to change(p.master.option_values(true), :count).by(0)
          p.reload
          p.master.option_values.map(&:name).include?("1L").should == true
          p.master.option_values.map(&:name).include?("1g").should == false
        end
      end

      it "finds all variant unit option types" do
        ot1 = create(:option_type, name: 'unit_weight', presentation: 'Weight')
        ot2 = create(:option_type, name: 'unit_volume', presentation: 'Volume')
        ot3 = create(:option_type, name: 'unit_items', presentation: 'Items')
        ot4 = create(:option_type, name: 'foo_unit_bar', presentation: 'Foo')

        Spree::Product.all_variant_unit_option_types.should match_array [ot1, ot2, ot3]
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
        it "returns on-demand products" do
          p = create(:simple_product, on_demand: true)
          p.variants.first.update_attributes!(count_on_hand: 0, on_demand: true)
          d = create(:distributor_enterprise)
          oc = create(:simple_order_cycle, distributors: [d])
          oc.exchanges.outgoing.first.variants << p.variants.first

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

    describe "taxons" do
      let(:taxon1) { create(:taxon) }
      let(:taxon2) { create(:taxon) }
      let(:product) { create(:simple_product) }

      it "returns the first taxon as the primary taxon" do
        product.taxons.should == [product.primary_taxon]
      end
    end

    describe "deletion" do
      let(:p)  { create(:simple_product) }
      let(:v)  { create(:variant, product: p) }
      let(:oc) { create(:simple_order_cycle) }
      let(:s)  { create(:supplier_enterprise) }
      let(:e)  { create(:exchange, order_cycle: oc, incoming: true, sender: s, receiver: oc.coordinator) }

      it "removes the master variant from all order cycles" do
        e.variants << p.master
        p.delete
        e.variants(true).should be_empty
      end

      it "removes all other variants from order cycles" do
        e.variants << v
        p.delete
        e.variants(true).should be_empty
      end
    end
  end
end
