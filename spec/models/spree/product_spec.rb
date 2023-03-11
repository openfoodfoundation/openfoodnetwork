# frozen_string_literal: false

require 'spec_helper'
require 'spree/core/product_duplicator'

module Spree
  describe Product do
    context 'product instance' do
      let(:product) { create(:product) }

      context '#duplicate' do
        before do
          allow(product).to receive_messages taxons: [create(:taxon)]
        end

        it 'duplicates product' do
          clone = product.duplicate
          expect(clone.name).to eq 'COPY OF ' + product.name
          expect(clone.master.sku).to eq ''
          expect(clone.images.size).to eq product.images.size
        end
      end

      context "product has no variants" do
        context "#destroy" do
          it "should set deleted_at value" do
            product.destroy
            expect(product.deleted_at).to_not be_nil
            expect(product.master.deleted_at).to_not be_nil
          end
        end
      end

      context "product has variants" do
        before do
          create(:variant, product: product)
        end

        context "#destroy" do
          it "should set deleted_at value" do
            product.destroy
            expect(product.deleted_at).to_not be_nil
            expect(product.variants_including_master.all? { |v| !v.deleted_at.nil? }).to be_truthy
          end
        end
      end

      context "#price" do
        # Regression test for Spree #1173
        it 'strips non-price characters' do
          product.price = "$10"
          expect(product.price).to eq 10.0
        end
      end

      context "#display_price" do
        before { product.price = 10.55 }

        context "with display_currency set to true" do
          before { Spree::Config[:display_currency] = true }

          it "shows the currency" do
            expect(product.display_price.to_s).to eq "$10.55 #{Spree::Config[:currency]}"
          end
        end

        context "with display_currency set to false" do
          before { Spree::Config[:display_currency] = false }

          it "does not include the currency" do
            expect(product.display_price.to_s).to eq "$10.55"
          end
        end

        context "with currency set to JPY" do
          before do
            product.master.default_price.currency = 'JPY'
            product.master.default_price.save!
            Spree::Config[:currency] = 'JPY'
          end

          it "displays the currency in yen" do
            expect(product.display_price.to_s).to eq "¥11"
          end
        end
      end

      describe 'Variants sorting' do
        context 'without master variant' do
          it 'sorts variants by position' do
            expect(product.variants.to_sql).to match(/ORDER BY spree_variants.position ASC/)
          end
        end

        context 'with master variant' do
          it 'sorts variants by position' do
            expect(product.variants_including_master.to_sql).to match(/ORDER BY spree_variants.position ASC/)
          end
        end
      end
    end

    context "permalink" do
      context "build product with similar name" do
        let!(:other) { create(:product, name: 'foo bar') }
        let(:product) { build(:product, name: 'foo') }

        before { product.valid? }

        it "increments name" do
          expect(product.permalink).to eq 'foo-1'
        end
      end

      context "build permalink with quotes" do
        it "does not save quotes" do
          product = create(:product, name: "Joe's", permalink: "joe's")
          expect(product.permalink).to eq "joe-s"
        end
      end

      context "permalinks must be unique" do
        before do
          @product1 = create(:product, name: 'foo')
        end

        it "cannot create another product with the same permalink" do
          pending '[Spree build] Failing spec'
          @product2 = create(:product, name: 'foo')
          expect do
            @product2.update(permalink: @product1.permalink)
          end.to raise_error(ActiveRecord::RecordNotUnique)
        end
      end

      it "supports Chinese" do
        expect(create(:product, name: "你好").permalink).to eq "ni-hao"
      end

      context "manual permalink override" do
        let(:product) { create(:product, name: "foo") }

        it "calling save_permalink with a parameter" do
          product.name = "foobar"
          product.save
          expect(product.permalink).to eq "foo"

          product.save_permalink(product.name)
          expect(product.permalink).to eq "foobar"
        end
      end

      context "override permalink of deleted product" do
        let(:product) { create(:product, name: "foo") }

        it "should create product with same permalink from name like deleted product" do
          expect(product.permalink).to eq "foo"
          product.destroy

          new_product = create(:product, name: "foo")
          expect(new_product.permalink).to eq "foo"
        end
      end
    end

    context "properties" do
      let(:product) { create(:product) }

      it "should properly assign properties" do
        product.set_property('the_prop', 'value1')
        expect(product.property('the_prop')).to eq 'value1'

        product.set_property('the_prop', 'value2')
        expect(product.property('the_prop')).to eq 'value2'
      end

      it "should not create duplicate properties when set_property is called" do
        expect {
          product.set_property('the_prop', 'value2')
          product.save
          product.reload
        }.not_to change(product.properties, :length)

        expect {
          product.set_property('the_prop_new', 'value')
          product.save
          product.reload
          expect(product.property('the_prop_new')).to eq 'value'
        }.to change { product.properties.length }.by(1)
      end

      # Regression test for #2455
      it "should not overwrite properties' presentation names" do
        Spree::Property.where(name: 'foo').first_or_create!(presentation: "Foo's Presentation Name")
        product.set_property('foo', 'value1')
        product.set_property('bar', 'value2')
        expect(Spree::Property.where(name: 'foo').first.presentation).to eq "Foo's Presentation Name"
        expect(Spree::Property.where(name: 'bar').first.presentation).to eq "bar"
      end
    end

    describe "supplier properties" do
      subject { create(:product) }

      it "has no supplier properties to start with" do
        expect(subject.supplier_properties).to eq []
      end

      it "doesn't include product properties" do
        subject.set_property("certified", "organic")
        expect(subject.supplier_properties).to eq []
      end

      it "includes the supplier's properties" do
        subject.supplier.set_producer_property("certified", "yes")
        expect(subject.supplier_properties.map(&:presentation)).to eq ["certified"]
      end
    end

    describe ".with_properties scope" do
      let!(:product_without_wanted_property_on_supplier) { create(:product, supplier: supplier_without_wanted_property) }
      let!(:product_with_wanted_property_on_supplier) { create(:product, supplier: supplier_with_wanted_property) }
      let!(:product_with_wanted_property) { create(:product, properties: [wanted_property]) }
      let!(:product_without_wanted_property_property) { create(:product, properties: [unwanted_property]) }
      let!(:product_with_wanted_property_and_on_supplier) { create(:product, properties: [wanted_property], supplier: supplier_with_wanted_property) }
      let!(:product_ignoring_property) { create(:product, supplier: supplier_with_wanted_property, inherits_properties: false) }
      let(:supplier_with_wanted_property) { create(:supplier_enterprise, properties: [wanted_property]) }
      let(:supplier_without_wanted_property) { create(:supplier_enterprise, properties: [unwanted_property]) }
      let(:wanted_property) { create(:property, presentation: 'Certified Organic') }
      let(:unwanted_property) { create(:property, presentation: 'Latest Hype') }

      it "returns no products without a property id" do
        expect(Spree::Product.with_properties([])).to eq []
      end

      it "returns only products with the wanted property set both on supplier and on the product itself" do
        expect(
          Spree::Product.with_properties([wanted_property.id])
        ).to match_array [
          product_with_wanted_property_on_supplier,
          product_with_wanted_property,
          product_with_wanted_property_and_on_supplier
        ]
      end
    end

    # Regression tests for Spree #2352
    context "classifications and taxons" do
      it "is joined through classifications" do
        reflection = Spree::Product.reflect_on_association(:taxons)
        reflection.options[:through] = :classifications
      end

      it "will delete all classifications" do
        reflection = Spree::Product.reflect_on_association(:classifications)
        reflection.options[:dependent] = :delete_all
      end
    end

    describe '#total_on_hand' do
      it 'returns sum of stock items count_on_hand' do
        product = build(:product)
        allow(product).to receive_messages stock_items: [double(Spree::StockItem, count_on_hand: 5)]
        expect(product.total_on_hand).to eql(5)
      end
    end

    context "has stock movements" do
      let(:product) { create(:product) }
      let(:variant) { product.master }
      let(:stock_item) { variant.stock_items.first }

      it "doesnt raise ReadOnlyRecord error" do
        Spree::StockMovement.create!(stock_item: stock_item, quantity: 1)
        expect { product.destroy }.not_to raise_error
      end
    end

    describe "associations" do
      it { is_expected.to belong_to(:supplier) }
      it { is_expected.to belong_to(:primary_taxon) }
    end

    describe "validations and defaults" do
      it "is valid when built from factory" do
        expect(build(:product)).to be_valid
      end

      it "requires a primary taxon" do
        expect(build(:simple_product, taxons: [], primary_taxon: nil)).not_to be_valid
      end

      it "requires a unit value" do
        expect(build(:simple_product, unit_value: nil)).not_to be_valid
      end

      it "requires a supplier" do
        expect(build(:simple_product, supplier: nil)).not_to be_valid
      end

      it "does not save when master is invalid" do
        product = build(:product)
        product.variant_unit = 'weight'
        product.master.unit_value = nil

        expect(product.save).to eq(false)
      end

      it "defaults available_on to now" do
        Timecop.freeze do
          product = Product.new
          expect(product.available_on).to be_within(0.000001).of(Time.zone.now)
        end
      end

      describe "permalink" do
        let(:name) { "Banana Permanenta" }

        it "generates a unique permalink" do
          product1 = create(:product, name: "Banana Permanenta", permalink: nil)
          product2 = build_stubbed(:product, name: "Banana Permanenta", permalink: nil)
          expect(product2).to be_valid
          expect(product2.permalink).to_not eq product1.permalink
          # "banana-permanenta" != "banana-permanenta-1" # generated by Spree
        end

        it "generates a unique permalink considering deleted products" do
          product1 = create(:product, name: "Banana Permanenta", permalink: nil)
          product1.destroy
          product2 = create(:product, name: "Banana Permanenta", permalink: nil)
          expect(product2.permalink).to_not eq product1.permalink
          # "banana-permanenta" != "banana-permanenta1" # generated by OFN
        end
      end

      describe "tax category" do
        context "when a tax category is required" do
          it "is invalid when a tax category is not provided" do
            with_products_require_tax_category(true) do
              expect(build(:product, tax_category_id: nil)).not_to be_valid
            end
          end
        end

        context "when a tax category is not required" do
          it "is valid when a tax category is not provided" do
            with_products_require_tax_category(false) do
              expect(build(:product, tax_category_id: nil)).to be_valid
            end
          end
        end
      end

      context "when the product has variants" do
        let(:product) do
          product = create(:simple_product)
          create(:variant, product: product)
          product.reload
        end

        it "requires a unit" do
          product.variant_unit = nil
          expect(product).not_to be_valid
        end

        %w(weight volume).each do |unit|
          context "when unit is #{unit}" do
            it "is valid when unit scale is set and unit name is not" do
              product.variant_unit = unit
              product.variant_unit_scale = 1
              product.variant_unit_name = nil
              expect(product).to be_valid
            end

            it "is invalid when unit scale is not set" do
              product.variant_unit = unit
              product.variant_unit_scale = nil
              product.variant_unit_name = nil
              expect(product).not_to be_valid
            end
          end
        end

        context "saving a new product" do
          let!(:product){ Spree::Product.new }

          before do
            create(:stock_location)
            product.primary_taxon = create(:taxon)
            product.supplier = create(:supplier_enterprise)
            product.name = "Product1"
            product.variant_unit = "weight"
            product.variant_unit_scale = 1000
            product.unit_value = 1
            product.price = 4.27
            product.shipping_category = create(:shipping_category)
            product.save!
          end

          it "copies the properties on master variant to the first standard variant" do
            expect(product.variants.reload.length).to eq 1
            standard_variant = product.variants.reload.first
            expect(standard_variant.price).to eq product.master.price
          end

          it "only duplicates master with after_save when no standard variants exist" do
            expect(product).to receive :ensure_standard_variant
            product.name = "Something else"
            expect{ product.save! }.to_not change{ product.variants.count }
          end
        end

        context "when the unit is items" do
          it "is valid when unit name is set and unit scale is not" do
            product.variant_unit = 'items'
            product.variant_unit_name = 'loaf'
            product.variant_unit_scale = nil
            expect(product).to be_valid
          end

          it "is invalid when unit name is not set" do
            product.variant_unit = 'items'
            product.variant_unit_name = nil
            product.variant_unit_scale = nil
            expect(product).not_to be_valid
          end
        end
      end

      context "a basic product" do
        let(:product) { build_stubbed(:simple_product) }

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

          expect(product).not_to be_valid
        end
      end
    end

    describe "callbacks" do
      let(:product) { create(:simple_product) }

      describe "touching affected enterprises when the product is deleted" do
        let(:product) { create(:simple_product) }
        let(:supplier) { product.supplier }
        let(:distributor) { create(:distributor_enterprise) }
        let!(:oc) {
          create(:simple_order_cycle, distributors: [distributor],
                                      variants: [product.variants.first])
        }

        it "touches the supplier" do
          expect { product.destroy }.to change { supplier.reload.updated_at }
        end

        it "touches all distributors" do
          expect { product.destroy }.to change { distributor.reload.updated_at }
        end

        it "removes variants from order cycles" do
          expect { product.destroy }.to change { ExchangeVariant.count }
        end
      end

      it "adds the primary taxon to the product's taxon list" do
        taxon = create(:taxon)
        product = create(:product, primary_taxon: taxon)

        expect(product.taxons).to include(taxon)
      end

      it "removes the previous primary taxon from the taxon list" do
        original_taxon = create(:taxon)
        product = create(:product, primary_taxon: original_taxon)
        product.primary_taxon = create(:taxon)
        product.save!

        expect(product.taxons).not_to include(original_taxon)
      end

      it "updates units when saved change to variant unit" do
        product.variant_unit = 'items'
        product.variant_unit_scale = nil
        product.variant_unit_name = 'loaf'
        product.save!

        expect(product.variant_unit_name).to eq 'loaf'

        product.update(variant_unit_name: 'bag')

        expect(product.variant_unit_name).to eq 'bag'

        product.variant_unit = 'weight'
        product.variant_unit_scale = 1
        product.variant_unit_name = 'g'
        product.save!

        expect(product.variant_unit).to eq 'weight'

        product.update(variant_unit: 'volume')

        expect(product.variant_unit).to eq 'volume'
      end
    end

    describe "scopes" do
      describe "in_supplier" do
        it "shows products in supplier" do
          s1 = create(:supplier_enterprise)
          s2 = create(:supplier_enterprise)
          p1 = create(:product, supplier: s1)
          p2 = create(:product, supplier: s2)
          expect(Product.in_supplier(s1)).to eq([p1])
        end
      end

      describe "in_distributor" do
        it "shows products in order cycle distribution" do
          s = create(:supplier_enterprise)
          d1 = create(:distributor_enterprise)
          d2 = create(:distributor_enterprise)
          p1 = create(:product)
          p2 = create(:product)
          create(:simple_order_cycle, suppliers: [s], distributors: [d1], variants: [p1.master])
          create(:simple_order_cycle, suppliers: [s], distributors: [d2], variants: [p2.master])
          expect(Product.in_distributor(d1)).to eq([p1])
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
          expect(Product.in_distributor(d1)).to eq([p1])
        end

        it "doesn't show products listed in the incoming exchange only" do
          s = create(:supplier_enterprise)
          c = create(:distributor_enterprise)
          d = create(:distributor_enterprise)
          p = create(:product)
          oc = create(:simple_order_cycle, coordinator: c, suppliers: [s], distributors: [d])
          ex = oc.exchanges.incoming.first
          ex.variants << p.master

          expect(Product.in_distributor(d)).to be_empty
        end
      end

      describe "in_distributors" do
        let!(:distributor1) { create(:distributor_enterprise) }
        let!(:distributor2) { create(:distributor_enterprise) }
        let!(:product1) { create(:product) }
        let!(:product2) { create(:product) }
        let!(:product3) { create(:product) }
        let!(:product4) { create(:product) }
        let!(:order_cycle1) {
          create(:order_cycle, distributors: [distributor1],
                               variants: [product1.variants.first, product2.variants.first])
        }
        let!(:order_cycle2) {
          create(:order_cycle, distributors: [distributor2],
                               variants: [product3.variants.first])
        }

        it "returns distributed products for a given Enterprise AR relation" do
          distributors = Enterprise.where(id: [distributor1.id, distributor2.id]).to_a

          expect(Product.in_distributors(distributors)).to include product1, product2, product3
          expect(Product.in_distributors(distributors)).to_not include product4
        end

        it "returns distributed products for a given array of enterprise ids" do
          distributors_ids = [distributor1.id, distributor2.id]

          expect(Product.in_distributors(distributors_ids)).to include product1, product2, product3
          expect(Product.in_distributors(distributors_ids)).to_not include product4
        end
      end

      describe "in_supplier_or_distributor" do
        it "shows products in supplier" do
          s1 = create(:supplier_enterprise)
          s2 = create(:supplier_enterprise)
          p1 = create(:product, supplier: s1)
          p2 = create(:product, supplier: s2)
          expect(Product.in_supplier_or_distributor(s1)).to eq([p1])
        end

        it "shows products in order cycle distribution" do
          s = create(:supplier_enterprise)
          d1 = create(:distributor_enterprise)
          d2 = create(:distributor_enterprise)
          p1 = create(:product)
          p2 = create(:product)
          create(:simple_order_cycle, suppliers: [s], distributors: [d1], variants: [p1.master])
          create(:simple_order_cycle, suppliers: [s], distributors: [d2], variants: [p2.master])
          expect(Product.in_supplier_or_distributor(d1)).to eq([p1])
        end

        it "shows products in all three without duplicates" do
          s = create(:supplier_enterprise)
          d = create(:distributor_enterprise)
          p = create(:product, supplier: s)
          create(:simple_order_cycle, suppliers: [s], distributors: [d], variants: [p.master])
          [s, d].each { |e| expect(Product.in_supplier_or_distributor(e)).to eq([p]) }
        end
      end

      describe "in_order_cycle" do
        it "shows products in order cycle distribution" do
          s = create(:supplier_enterprise)
          d1 = create(:distributor_enterprise)
          d2 = create(:distributor_enterprise)
          p1 = create(:product)
          p2 = create(:product)
          oc1 = create(:simple_order_cycle, suppliers: [s], distributors: [d1],
                                            variants: [p1.master])
          oc2 = create(:simple_order_cycle, suppliers: [s], distributors: [d2],
                                            variants: [p2.master])
          expect(Product.in_order_cycle(oc1)).to eq([p1])
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
          oc2 = create(:simple_order_cycle, suppliers: [s], distributors: [d2],
                                            variants: [p2.master], orders_open_at: 8.days.ago, orders_close_at: 1.day.ago)
          oc2 = create(:simple_order_cycle, suppliers: [s], distributors: [d3],
                                            variants: [p3.master], orders_close_at: Date.tomorrow)
          expect(Product.in_an_active_order_cycle).to eq([p3])
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
          expect(product.count).to eq(1)
          expect(product).to include @p1
        end

        it "shows all products for admin user" do
          user = create(:admin_user)

          product = Product.managed_by user
          expect(product.count).to eq(2)
          expect(product).to include @p1
          expect(product).to include @p2
        end
      end

      describe "visible_for" do
        let(:enterprise) { create(:distributor_enterprise) }
        let!(:new_variant) { create(:variant) }
        let!(:hidden_variant) { create(:variant) }

        let!(:product) { create(:product) }
        let!(:visible_variant1) { create(:variant, product: product) }
        let!(:visible_variant2) { create(:variant, product: product) }

        let!(:hidden_inventory_item) {
          create(:inventory_item, enterprise: enterprise, variant: hidden_variant, visible: false )
        }
        let!(:visible_inventory_item1) {
          create(:inventory_item, enterprise: enterprise, variant: visible_variant1, visible: true )
        }
        let!(:visible_inventory_item2) {
          create(:inventory_item, enterprise: enterprise, variant: visible_variant2, visible: true )
        }

        let!(:products) { Spree::Product.visible_for(enterprise) }

        it "lists any products with variants that are listed as visible=true" do
          expect(products.length).to eq(1)
          expect(products).to include product
          expect(products).to_not include new_variant.product, hidden_variant.product
        end
      end

      describe 'stockable_by' do
        let(:shop) { create(:distributor_enterprise) }
        let(:add_to_oc_producer) { create(:supplier_enterprise) }
        let(:other_producer) { create(:supplier_enterprise) }
        let!(:p1) { create(:simple_product, supplier: shop ) }
        let!(:p2) { create(:simple_product, supplier: add_to_oc_producer ) }
        let!(:p3) { create(:simple_product, supplier: other_producer ) }

        before do
          create(:enterprise_relationship, parent: add_to_oc_producer, child: shop,
                                           permissions_list: [:add_to_order_cycle])
          create(:enterprise_relationship, parent: other_producer, child: shop,
                                           permissions_list: [:manage_products])
        end

        it 'shows products produced by the enterprise and any producers granting P-OC' do
          stockable_products = Spree::Product.stockable_by(shop)
          expect(stockable_products).to include p1, p2
          expect(stockable_products).to_not include p3
        end
      end

      describe "imported_on" do
        let!(:v1) { create(:variant, import_date: 1.day.ago) }
        let!(:v2) { create(:variant, import_date: 2.days.ago) }
        let!(:v3) { create(:variant, import_date: 1.day.ago) }

        it "returns products imported on given day" do
          imported_products = Spree::Product.imported_on(1.day.ago.to_date)
          expect(imported_products).to include v1.product, v3.product
        end
      end
    end

    describe "properties" do
      it "returns product properties as a hash" do
        product = create(:simple_product)
        product.set_property 'Organic Certified', 'NASAA 12345'
        property = product.properties.last

        expect(product.properties_including_inherited).to eq([{ id: property.id,
                                                                name: "Organic Certified", value: 'NASAA 12345' }])
      end

      it "returns producer properties as a hash" do
        supplier = create(:supplier_enterprise)
        product = create(:simple_product, supplier: supplier)

        supplier.set_producer_property 'Organic Certified', 'NASAA 54321'
        property = supplier.properties.last

        expect(product.properties_including_inherited).to eq([{ id: property.id,
                                                                name: "Organic Certified", value: 'NASAA 54321' }])
      end

      it "overrides producer properties with product properties" do
        supplier = create(:supplier_enterprise)
        product = create(:simple_product, supplier: supplier)

        product.set_property 'Organic Certified', 'NASAA 12345'
        supplier.set_producer_property 'Organic Certified', 'NASAA 54321'
        property = product.properties.last

        expect(product.properties_including_inherited).to eq([{ id: property.id,
                                                                name: "Organic Certified", value: 'NASAA 12345' }])
      end

      context "when product has an inherit_properties value set to true" do
        let(:supplier) { create(:supplier_enterprise) }
        let(:product) { create(:simple_product, supplier: supplier, inherits_properties: true) }

        it "inherits producer properties" do
          supplier.set_producer_property 'Organic Certified', 'NASAA 54321'
          property = supplier.properties.last

          expect(product.properties_including_inherited).to eq([{ id: property.id,
                                                                  name: "Organic Certified", value: 'NASAA 54321' }])
        end
      end

      context "when product has an inherit_properties value set to false" do
        let(:supplier) { create(:supplier_enterprise) }
        let(:product) { create(:simple_product, supplier: supplier, inherits_properties: false) }

        it "does not inherit producer properties" do
          supplier.set_producer_property 'Organic Certified', 'NASAA 54321'

          expect(product.properties_including_inherited).to eq([])
        end
      end

      it "sorts by position" do
        supplier = create(:supplier_enterprise)
        product = create(:simple_product, supplier: supplier)

        pa = Spree::Property.create! name: 'A', presentation: 'A'
        pb = Spree::Property.create! name: 'B', presentation: 'B'
        pc = Spree::Property.create! name: 'C', presentation: 'C'

        product.product_properties.create!({ property_id: pa.id, value: '1', position: 1 })
        product.product_properties.create!({ property_id: pc.id, value: '3', position: 3 })
        supplier.producer_properties.create!({ property_id: pb.id, value: '2', position: 2 })

        expect(product.properties_including_inherited).to eq(
          [{ id: pa.id, name: "A", value: '1' },
           { id: pb.id, name: "B", value: '2' },
           { id: pc.id, name: "C", value: '3' }]
        )
      end
    end

    describe "membership" do
      it "queries its membership of a particular order cycle distribution" do
        d1 = create(:distributor_enterprise)
        d2 = create(:distributor_enterprise)
        p1 = create(:product)
        p2 = create(:product)
        oc1 = create(:simple_order_cycle, distributors: [d1], variants: [p1.master])
        oc2 = create(:simple_order_cycle, distributors: [d2], variants: [p2.master])

        expect(p1).to be_in_distributor d1
        expect(p1).not_to be_in_distributor d2
      end

      it "queries its membership of a particular order cycle" do
        d1 = create(:distributor_enterprise)
        d2 = create(:distributor_enterprise)
        p1 = create(:product)
        p2 = create(:product)
        oc1 = create(:simple_order_cycle, distributors: [d1], variants: [p1.master])
        oc2 = create(:simple_order_cycle, distributors: [d2], variants: [p2.master])

        expect(p1).to be_in_order_cycle oc1
        expect(p1).not_to be_in_order_cycle oc2
      end
    end

    describe "variant units" do
      context "when the product already has a variant unit set (and all required option types exist)" do
        let!(:p) {
          create(:simple_product,
                 variant_unit: 'weight',
                 variant_unit_scale: 1,
                 variant_unit_name: nil)
        }

        let!(:ot_volume) { create(:option_type, name: 'unit_volume', presentation: 'Volume') }

        it "removes the old option type and assigns the new one" do
          p.update!(variant_unit: 'volume', variant_unit_scale: 0.001)
          expect(p.option_types).to eq([ot_volume])
        end

        it "does not remove and re-add the option type if it is not changed" do
          expect(p.option_types).to receive(:delete).never
          p.update!(name: 'foo')
        end

        it "removes the related option values from all its variants and replaces them" do
          ot = Spree::OptionType.find_by name: 'unit_weight'
          v = create(:variant, unit_value: 1, product: p)
          p.reload

          expect(v.option_values.map(&:name).include?("1L")).to eq(false)
          expect(v.option_values.map(&:name).include?("1g")).to eq(true)
          expect {
            p.update!(variant_unit: 'volume', variant_unit_scale: 0.001)
          }.to change(p.master.option_values.reload, :count).by(0)
          v.reload
          expect(v.option_values.map(&:name).include?("1L")).to eq(true)
          expect(v.option_values.map(&:name).include?("1g")).to eq(false)
        end

        it "removes the related option values from its master variant and replaces them" do
          ot = Spree::OptionType.find_by name: 'unit_weight'
          p.master.update!(unit_value: 1)
          p.reload

          expect(p.master.option_values.map(&:name).include?("1L")).to eq(false)
          expect(p.master.option_values.map(&:name).include?("1g")).to eq(true)
          expect {
            p.update!(variant_unit: 'volume', variant_unit_scale: 0.001)
          }.to change(p.master.option_values.reload, :count).by(0)
          p.reload
          expect(p.master.option_values.map(&:name).include?("1L")).to eq(true)
          expect(p.master.option_values.map(&:name).include?("1g")).to eq(false)
        end
      end

      it "finds all variant unit option types" do
        ot1 = create(:option_type, name: 'unit_weight', presentation: 'Weight')
        ot2 = create(:option_type, name: 'unit_volume', presentation: 'Volume')
        ot3 = create(:option_type, name: 'unit_items', presentation: 'Items')
        ot4 = create(:option_type, name: 'foo_unit_bar', presentation: 'Foo')

        expect(Spree::Product.all_variant_unit_option_types).to match_array [ot1, ot2, ot3]
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
          expect(v1.option_values.reload).not_to include ov1
          expect(v2.option_values.reload).not_to include ov2

          # And the option values themselves should still exist
          expect(Spree::OptionValue.where(id: [ov1.id, ov2.id]).count).to eq(2)
        end
      end
    end

    describe "taxons" do
      let(:taxon1) { create(:taxon) }
      let(:taxon2) { create(:taxon) }
      let(:product) { create(:simple_product) }

      it "returns the first taxon as the primary taxon" do
        expect(product.taxons).to eq([product.primary_taxon])
      end
    end

    describe "deletion" do
      let(:p)  { create(:simple_product) }
      let(:v)  { create(:variant, product: p) }
      let(:oc) { create(:simple_order_cycle) }
      let(:s)  { create(:supplier_enterprise) }
      let(:e)  {
        create(:exchange, order_cycle: oc, incoming: true, sender: s, receiver: oc.coordinator)
      }

      it "removes the master variant from all order cycles" do
        e.variants << p.master
        p.destroy
        expect(e.variants.reload).to be_empty
      end

      it "removes all other variants from order cycles" do
        e.variants << v
        p.destroy
        expect(e.variants.reload).to be_empty
      end
    end
  end

  describe "product import" do
    describe "finding the most recent import date of the variants" do
      let!(:product) { create(:product) }

      let(:reference_time) { Time.zone.now.beginning_of_day }

      before do
        product.reload
      end

      context "when the variants do not have an import date" do
        let!(:variant_a) { create(:variant, product: product, import_date: nil) }
        let!(:variant_b) { create(:variant, product: product, import_date: nil) }

        it "returns nil" do
          expect(product.import_date).to be_nil
        end
      end

      context "when some variants have import date and some do not" do
        let!(:variant_a) { create(:variant, product: product, import_date: nil) }
        let!(:variant_b) {
          create(:variant, product: product, import_date: reference_time - 1.hour)
        }
        let!(:variant_c) {
          create(:variant, product: product, import_date: reference_time - 2.hours)
        }

        it "returns the most recent import date" do
          expect(product.import_date).to eq(variant_b.import_date)
        end
      end

      context "when all variants have import date" do
        let!(:variant_a) {
          create(:variant, product: product, import_date: reference_time - 2.hours)
        }
        let!(:variant_b) {
          create(:variant, product: product, import_date: reference_time - 1.hour)
        }
        let!(:variant_c) {
          create(:variant, product: product, import_date: reference_time - 3.hours)
        }

        it "returns the most recent import date" do
          expect(product.import_date).to eq(variant_b.import_date)
        end
      end
    end
  end
end
