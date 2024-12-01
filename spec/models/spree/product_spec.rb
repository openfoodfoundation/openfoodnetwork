# frozen_string_literal: false

require 'spec_helper'
require 'spree/core/product_duplicator'

module Spree
  RSpec.describe Product do
    context 'product instance' do
      let(:product) { create(:product) }

      context '#duplicate' do
        it 'duplicates product' do
          clone = product.duplicate

          expect(clone).to be_persisted
          expect(clone.name).to eq "COPY OF #{product.name}"
          expect(clone.sku).to eq ""
          expect(clone.image).to eq product.image
        end

        it 'fails to duplicate invalid product' do
          # cloned product will be invalid
          product.update_columns(name: "l" * 254)

          expect{ product.duplicate }.to raise_error(ActiveRecord::ActiveRecordError)
        end
      end

      context "product has variants" do
        before do
          product.reload.variants << create(:variant, product:)
        end

        context "#destroy" do
          it "should set deleted_at value" do
            product.destroy
            expect(product.deleted_at).not_to be_nil
            expect(product.variants.all? { |v| !v.deleted_at.nil? }).to be_truthy
          end
        end
      end

      describe 'Variants sorting' do
        it 'sorts variants by id' do
          expect(product.variants.to_sql).to match(/ORDER BY spree_variants.id ASC/)
        end
      end
    end

    context "properties" do
      let(:product) { create(:product) }

      it "should properly assign properties" do
        expect {
          product.set_property('the_prop', 'value1')
          product.save
          product.reload
        }.to change { product.properties.length }.by(1)
        expect(product.property('the_prop')).to eq 'value1'

        product.set_property('the_prop', 'value2')
        expect(product.property('the_prop')).to eq 'value2'
      end

      it "should not create duplicate properties when set_property is called" do
        product.set_property('the_prop', 'value2')
        product.save

        expect {
          product.set_property('the_prop', 'value2')
          product.save
          product.reload
        }.not_to change { product.properties.length }
      end

      # Regression test for #2455
      it "should not overwrite properties' presentation names" do
        Spree::Property.where(name: 'foo').first_or_create!(presentation: "Foo's Presentation Name")
        product.set_property('foo', 'value1')
        product.set_property('bar', 'value2')
        expect(Spree::Property.where(name: 'foo').first.presentation)
          .to eq "Foo's Presentation Name"
        expect(Spree::Property.where(name: 'bar').first.presentation).to eq "bar"
      end
    end

    context "has stock movements" do
      let(:product) { create(:product) }
      let(:variant) { product.variants.first }
      let(:stock_item) { variant.stock_items.first }

      it "doesnt raise ReadOnlyRecord error" do
        Spree::StockMovement.create!(stock_item:, quantity: 1)
        expect { product.destroy }.not_to raise_error
      end
    end

    describe "associations" do
      it { is_expected.to have_one(:image) }

      it { is_expected.to have_many(:product_properties) }
      it { is_expected.to have_many(:properties).through(:product_properties) }
      it { is_expected.to have_many(:variants) }
      it { is_expected.to have_many(:prices).through(:variants) }
      it { is_expected.to have_many(:stock_items).through(:variants) }
      it { is_expected.to have_many(:variant_images).through(:variants) }
    end

    describe "validations and defaults" do
      it "is valid when built from factory" do
        expect(build(:product)).to be_valid
      end

      it { is_expected.to validate_presence_of :name }
      it { is_expected.to validate_length_of(:name).is_at_most(255) }
      it { is_expected.to validate_length_of(:sku).is_at_most(255) }

      context "when the product has variants" do
        let(:product) do
          product = create(:simple_product)
          create(:variant, product:)
          product.reload
        end

        it { is_expected.to validate_numericality_of(:price).is_greater_than_or_equal_to(0) }

        context "saving a new product" do
          let!(:product){ Spree::Product.new }
          let!(:shipping_category){ create(:shipping_category) }
          let!(:taxon){ create(:taxon) }
          let(:supplier){ create(:enterprise) }

          before do
            create(:stock_location)
          end

          it "copies properties to the first standard variant" do
            product.primary_taxon_id = taxon.id
            product.name = "Product1"
            product.variant_unit = "weight"
            product.variant_unit_scale = 1000
            product.unit_value = 1
            product.unit_description = "some product"
            product.price = 4.27
            product.shipping_category_id = shipping_category.id
            product.supplier_id = supplier.id
            product.save(context: :create_and_create_standard_variant)

            expect(product.variants.reload.length).to eq 1
            standard_variant = product.variants.reload.first

            expect(standard_variant).to be_valid
            expect(standard_variant.variant_unit).to eq("weight")
            expect(standard_variant.variant_unit_scale).to eq(1000)
            expect(standard_variant.unit_value).to eq(1)
            expect(standard_variant.unit_description).to eq("some product")
            expect(standard_variant.price).to eq 4.27
            expect(standard_variant.shipping_category).to eq shipping_category
            expect(standard_variant.primary_taxon).to eq taxon
            expect(standard_variant.supplier).to eq supplier
          end

          context "with variant attributes" do
            it {
              is_expected.to validate_presence_of(:variant_unit)
                .on(:create_and_create_standard_variant)
            }
            it {
              is_expected.to validate_presence_of(:supplier_id)
                .on(:create_and_create_standard_variant)
            }
            it {
              is_expected.to validate_presence_of(:primary_taxon_id)
                .on(:create_and_create_standard_variant)
            }

            describe "unit_value" do
              subject { build(:simple_product, variant_unit: "items") }

              it {
                is_expected.to validate_numericality_of(:unit_value).is_greater_than(0)
                  .on(:create_and_create_standard_variant)
              }
              it {
                is_expected.not_to validate_presence_of(:unit_value)
                  .on(:create_and_create_standard_variant)
              }

              ["weight", "volume"].each do |variant_unit|
                context "when variant_unit is #{variant_unit}" do
                  subject { build(:simple_product, variant_unit:) }

                  it {
                    is_expected.to validate_presence_of(:unit_value)
                      .on(:create_and_create_standard_variant)
                  }
                end
              end

              describe "unit_description" do
                it {
                  is_expected.not_to validate_presence_of(:unit_description)
                    .on(:create_and_create_standard_variant)
                }

                context "when variant_unit is et and unit_value is nil" do
                  subject {
                    build(:simple_product, variant_unit: "items", unit_value: nil,
                                           unit_description: "box")
                  }

                  it {
                    is_expected.to validate_presence_of(:unit_description)
                      .on(:create_and_create_standard_variant)
                  }
                end
              end

              describe "variant_unit_scale" do
                it {
                  is_expected.not_to validate_presence_of(:variant_unit_scale)
                    .on(:create_and_create_standard_variant)
                }

                ["weight", "volume"].each do |variant_unit|
                  context "when variant_unit is #{variant_unit}" do
                    subject { build(:simple_product, variant_unit:) }

                    it {
                      is_expected.to validate_presence_of(:variant_unit_scale)
                        .on(:create_and_create_standard_variant)
                    }
                  end
                end
              end

              describe "variant_unit_name" do
                subject { build(:simple_product, variant_unit: "volume") }

                it {
                  is_expected.not_to validate_presence_of(:variant_unit_name)
                    .on(:create_and_create_standard_variant)
                }

                context "when variant_unit is items" do
                  subject { build(:simple_product, variant_unit: "items") }

                  it {
                    is_expected.to validate_presence_of(:variant_unit_name)
                      .on(:create_and_create_standard_variant)
                  }
                end
              end
            end
          end
        end
      end

      describe "#validate_image" do
        subject(:product) { create(:product_with_image) }

        context "when the image is invalid" do
          before { allow(product.image).to receive(:valid?).and_return(false) }

          context "and has been changed" do
            before { expect(product.image).to receive(:changed?).and_return(true) }

            it "adds an error message to the base object" do
              expect(product).not_to be_valid
              expect(product.errors[:base]).to include('Image attachment is not a valid image.')
            end
          end

          it "ignores if unchanged" do
            expect(product).to be_valid
          end
        end

        context "when image is valid" do
          it { is_expected.to be_valid }
        end

        context "when image is blank" do
          subject { create(:product) }

          it { is_expected.to be_valid }
        end
      end
    end

    describe "callbacks" do
      let(:product) { create(:simple_product) }

      describe "destroy product" do
        let(:product) { create(:simple_product, supplier_id: distributor.id) }
        let(:distributor) { create(:distributor_enterprise) }
        let!(:oc) {
          create(:simple_order_cycle, distributors: [distributor],
                                      variants: [product.variants.first])
        }

        it "removes variants from order cycles" do
          expect { product.destroy }.to change { ExchangeVariant.count }
        end
      end

      describe "after updating primary taxon" do
        let(:product) { create(:simple_product, supplier_id: supplier.id) }
        let(:supplier) { create(:supplier_enterprise) }
        let(:new_taxon) { create(:taxon) }

        it "touches the supplier" do
          expect { product.update(primary_taxon_id: new_taxon.id) }
            .to change { supplier.reload.updated_at }
        end

        context "when product has no variant" do
          it "doesn't blow up" do
            product.variants = []
            product.save!

            expect { product.update(primary_taxon_id: new_taxon.id) }.not_to raise_error
          end
        end
      end

      describe "after touching the product" do
        let(:product) { create(:simple_product, supplier_id: supplier.id) }
        let(:supplier) { create(:supplier_enterprise) }

        it "touches the supplier" do
          expect { product.touch }
            .to change { supplier.reload.updated_at }
        end

        context "when the first variant is missing supplier" do
          it "doesn't blow up" do
            product.variants.first.update_attribute(:supplier_id, nil)

            expect { product.touch }.not_to raise_error
          end
        end
      end
    end

    describe "scopes" do
      describe ".with_properties" do
        let!(:product_with_wanted_property) { create(:product, properties: [wanted_property]) }
        let!(:product_without_wanted_property_property) {
          create(:product, properties: [unwanted_property])
        }
        let!(:product_ignoring_property) {
          create(:product, inherits_properties: false)
        }
        let(:wanted_property) { create(:property, presentation: 'Certified Organic') }
        let(:unwanted_property) { create(:property, presentation: 'Latest Hype') }

        it "returns no products without a property id" do
          expect(Spree::Product.with_properties([])).to eq []
        end

        it "returns only products with the wanted property set both on supplier & product itself" do
          expect(
            Spree::Product.with_properties([wanted_property.id, 99_999])
          ).to match_array [product_with_wanted_property]
        end
      end

      describe "in_supplier" do
        it "shows products in supplier" do
          s1 = create(:supplier_enterprise)
          p1 = create(:product, supplier_id: s1.id)
          # We create two variants to let us test we don't get duplicated product
          create(:variant, product: p1, supplier: s1)
          create(:variant, product: p1, supplier: s1)
          s2 = create(:supplier_enterprise)
          p2 = create(:product, supplier_id: s2.id)
          create(:variant, product: p2, supplier: s2)

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
          create(:simple_order_cycle, suppliers: [s], distributors: [d1],
                                      variants: [p1.variants.first])
          create(:simple_order_cycle, suppliers: [s], distributors: [d2],
                                      variants: [p2.variants.first])
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
          ex.variants << p.variants.first

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
          expect(Product.in_distributors(distributors)).not_to include product4
        end

        it "returns distributed products for a given array of enterprise ids" do
          distributors_ids = [distributor1.id, distributor2.id]

          expect(Product.in_distributors(distributors_ids)).to include product1, product2, product3
          expect(Product.in_distributors(distributors_ids)).not_to include product4
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
                                            variants: [p1.variants.first])
          oc2 = create(:simple_order_cycle, suppliers: [s], distributors: [d2],
                                            variants: [p2.variants.first])
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
                                            variants: [p2.variants.first],
                                            orders_open_at: 8.days.ago, orders_close_at: 1.day.ago)
          oc2 = create(:simple_order_cycle, suppliers: [s], distributors: [d3],
                                            variants: [p3.variants.first],
                                            orders_close_at: Date.tomorrow)
          expect(Product.in_an_active_order_cycle).to eq([p3])
        end
      end

      describe "by_producer" do
        it "orders by producer name" do
          producer_z = create(:enterprise, name: "z_cooperative")
          producer_a = create(:enterprise, name: "a_cooperative")
          producer_g = create(:enterprise, name: "g_cooperative")

          product1 = create(:product, supplier_id: producer_z.id)
          product2 = create(:product, supplier_id: producer_a.id)
          product3 = create(:product, supplier_id: producer_g.id)

          expect(Product.by_producer).to eq([product2, product3, product1])
        end
      end

      describe "managed_by" do
        let!(:e1) { create(:enterprise) }
        let!(:e2) { create(:enterprise) }
        let!(:p1) { create(:product) }
        let!(:p2) { create(:product) }

        before(:each) do
          create(:variant, product: p1, supplier: e1)
          create(:variant, product: p1, supplier: e2)
        end

        it "shows only products for given user" do
          user = create(:user)
          user.spree_roles = []
          e1.enterprise_roles.build(user:).save

          product = Product.managed_by user

          expect(product.count).to eq(1)
          expect(product).to include p1
        end

        it "shows all products for admin user" do
          user = create(:admin_user)

          product = Product.managed_by user

          expect(product.count).to eq(2)
          expect(product).to include p1
          expect(product).to include p2
        end
      end

      describe "visible_for" do
        let(:enterprise) { create(:distributor_enterprise) }
        let!(:new_variant) { create(:variant) }
        let!(:hidden_variant) { create(:variant) }

        let!(:product) { create(:product) }
        let!(:visible_variant1) { create(:variant, product:) }
        let!(:visible_variant2) { create(:variant, product:) }

        let!(:hidden_inventory_item) {
          create(:inventory_item, enterprise:, variant: hidden_variant, visible: false )
        }
        let!(:visible_inventory_item1) {
          create(:inventory_item, enterprise:, variant: visible_variant1, visible: true )
        }
        let!(:visible_inventory_item2) {
          create(:inventory_item, enterprise:, variant: visible_variant2, visible: true )
        }

        let!(:products) { Spree::Product.visible_for(enterprise) }

        it "lists any products with variants that are listed as visible=true" do
          expect(products.length).to eq(1)
          expect(products).to include product
          expect(products).not_to include new_variant.product, hidden_variant.product
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

    describe "#properties_including_inherited" do
      let(:product) { create(:simple_product) }
      let(:supplier) { create(:supplier_enterprise) }

      before do
        product.variants = []
        product.variants << create(:variant, product:, supplier:)
      end

      it "returns product properties as a hash" do
        product.set_property 'Organic Certified', 'NASAA 12345'
        property = product.properties.last

        expect(product.properties_including_inherited)
          .to eq([{ id: property.id, name: "Organic Certified", value: 'NASAA 12345' }])
      end

      it "returns producer properties as a hash" do
        supplier.set_producer_property 'Organic Certified', 'NASAA 54321'
        property = supplier.properties.last

        expect(product.properties_including_inherited)
          .to eq([{ id: property.id, name: "Organic Certified", value: 'NASAA 54321' }])
      end

      it "overrides producer properties with product properties" do
        product.set_property 'Organic Certified', 'NASAA 12345'
        supplier.set_producer_property 'Organic Certified', 'NASAA 54321'
        property = product.properties.last

        expect(product.properties_including_inherited)
          .to eq([{ id: property.id, name: "Organic Certified", value: 'NASAA 12345' }])
      end

      context "when product has an inherit_properties value set to true" do
        let(:product) { create(:simple_product, inherits_properties: true) }

        it "inherits producer properties" do
          supplier.set_producer_property 'Organic Certified', 'NASAA 54321'
          property = supplier.properties.last

          expect(product.properties_including_inherited)
            .to eq([{ id: property.id, name: "Organic Certified", value: 'NASAA 54321' }])
        end
      end

      context "when product has an inherit_properties value set to false" do
        let(:product) { create(:simple_product, inherits_properties: false) }

        it "does not inherit producer properties" do
          supplier.set_producer_property 'Organic Certified', 'NASAA 54321'

          expect(product.properties_including_inherited).to eq([])
        end
      end

      it "sorts by position" do
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
        oc1 = create(:simple_order_cycle, distributors: [d1], variants: [p1.variants.first])
        oc2 = create(:simple_order_cycle, distributors: [d2], variants: [p2.variants.first])

        expect(p1).to be_in_distributor d1
        expect(p1).not_to be_in_distributor d2
      end

      it "queries its membership of a particular order cycle" do
        d1 = create(:distributor_enterprise)
        d2 = create(:distributor_enterprise)
        p1 = create(:product)
        p2 = create(:product)
        oc1 = create(:simple_order_cycle, distributors: [d1], variants: [p1.variants.first])
        oc2 = create(:simple_order_cycle, distributors: [d2], variants: [p2.variants.first])

        expect(p1).to be_in_order_cycle oc1
        expect(p1).not_to be_in_order_cycle oc2
      end
    end

    describe "deletion" do
      let(:product) { create(:simple_product) }
      let(:variant) { create(:variant, product:) }
      let(:order_cycle) { create(:simple_order_cycle) }
      let(:supplier) { create(:supplier_enterprise) }
      let(:exchange) {
        create(
          :exchange,
          order_cycle:,
          incoming: true,
          sender: supplier,
          receiver: order_cycle.coordinator
        )
      }

      it "removes all variants from order cycles" do
        exchange.variants << variant

        product.destroy
        expect(exchange.variants.reload).to be_empty
      end
    end

    describe "serialisation" do
      it "sanitises HTML in description" do
        subject.description = "Hello <script>alert</script> dearest <b>monster</b>."
        expect(subject.description).to eq "Hello alert dearest <b>monster</b>."
      end
    end
  end

  RSpec.describe "product import" do
    describe "finding the most recent import date of the variants" do
      let!(:product) { create(:product) }

      let(:reference_time) { Time.zone.now.beginning_of_day }

      before do
        product.reload
      end

      context "when the variants do not have an import date" do
        let!(:variant_a) { create(:variant, product:, import_date: nil) }
        let!(:variant_b) { create(:variant, product:, import_date: nil) }

        it "returns nil" do
          expect(product.import_date).to be_nil
        end
      end

      context "when some variants have import date and some do not" do
        let!(:variant_a) { create(:variant, product:, import_date: nil) }
        let!(:variant_b) {
          create(:variant, product:, import_date: reference_time - 1.hour)
        }
        let!(:variant_c) {
          create(:variant, product:, import_date: reference_time - 2.hours)
        }

        it "returns the most recent import date" do
          expect(product.import_date).to eq(variant_b.import_date)
        end
      end

      context "when all variants have import date" do
        let!(:variant_a) {
          create(:variant, product:, import_date: reference_time - 2.hours)
        }
        let!(:variant_b) {
          create(:variant, product:, import_date: reference_time - 1.hour)
        }
        let!(:variant_c) {
          create(:variant, product:, import_date: reference_time - 3.hours)
        }

        it "returns the most recent import date" do
          expect(product.import_date).to eq(variant_b.import_date)
        end
      end
    end
  end
end
