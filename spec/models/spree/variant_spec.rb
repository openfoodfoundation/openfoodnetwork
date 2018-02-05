require 'spec_helper'
require 'open_food_network/option_value_namer'
require 'open_food_network/products_cache'

module Spree
  describe Variant do
    describe "double loading" do
      # app/models/spree/variant_decorator.rb  may be double-loaded in delayed job environment,
      # so we need to be able to do so without error.
      it "succeeds without error" do
        load "#{Rails.root}/app/models/spree/variant_decorator.rb"
      end
    end

    describe "scopes" do
      it "finds non-deleted variants" do
        v_not_deleted = create(:variant)
        v_deleted = create(:variant, deleted_at: Time.zone.now)

        Spree::Variant.not_deleted.should     include v_not_deleted
        Spree::Variant.not_deleted.should_not include v_deleted
      end

      describe "finding variants in stock" do
        before do
          p = create(:product, on_hand: 0)
          @v_in_stock = create(:variant, product: p)
          @v_on_demand = create(:variant, product: p, on_demand: true)
          @v_no_stock = create(:variant, product: p)

          @v_in_stock.update_attribute(:count_on_hand, 1)
          @v_on_demand.update_attribute(:count_on_hand, 0)
          @v_no_stock.update_attribute(:count_on_hand, 0)
        end

        it "returns variants in stock or on demand, but not those that are neither" do
          Variant.where(is_master: false).in_stock.should match_array [@v_in_stock, @v_on_demand]
        end
      end

      describe "finding variants in a distributor" do
        let!(:d1) { create(:distributor_enterprise) }
        let!(:d2) { create(:distributor_enterprise) }
        let!(:p1) { create(:simple_product) }
        let!(:p2) { create(:simple_product) }
        let!(:oc1) { create(:simple_order_cycle, distributors: [d1], variants: [p1.master]) }
        let!(:oc2) { create(:simple_order_cycle, distributors: [d2], variants: [p2.master]) }

        it "shows variants in an order cycle distribution" do
          Variant.in_distributor(d1).should == [p1.master]
        end

        it "doesn't show duplicates" do
          oc_dup = create(:simple_order_cycle, distributors: [d1], variants: [p1.master])
          Variant.in_distributor(d1).should == [p1.master]
        end
      end

      describe "finding variants in an order cycle" do
        let!(:d1) { create(:distributor_enterprise) }
        let!(:d2) { create(:distributor_enterprise) }
        let!(:p1) { create(:product) }
        let!(:p2) { create(:product) }
        let!(:oc1) { create(:simple_order_cycle, distributors: [d1], variants: [p1.master]) }
        let!(:oc2) { create(:simple_order_cycle, distributors: [d2], variants: [p2.master]) }

        it "shows variants in an order cycle" do
          Variant.in_order_cycle(oc1).should == [p1.master]
        end

        it "doesn't show duplicates" do
          ex = create(:exchange, order_cycle: oc1, sender: oc1.coordinator, receiver: d2)
          ex.variants << p1.master

          Variant.in_order_cycle(oc1).should == [p1.master]
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
          p1.variants.for_distribution(oc, d1).should == [v1]
          p2.variants.for_distribution(oc, d2).should == [v2]
        end

        it "does not return variants in the order cycle but not the distributor" do
          p1.variants.for_distribution(oc, d2).should be_empty
          p2.variants.for_distribution(oc, d1).should be_empty
        end

        it "does not return variants not in the order cycle" do
          p_external.variants.for_distribution(oc, d1).should be_empty
        end
      end

      describe "finding variants based on visiblity in inventory" do
        let(:enterprise) { create(:distributor_enterprise) }
        let!(:new_variant) { create(:variant) }
        let!(:hidden_variant) { create(:variant) }
        let!(:visible_variant) { create(:variant) }

        let!(:hidden_inventory_item) { create(:inventory_item, enterprise: enterprise, variant: hidden_variant, visible: false ) }
        let!(:visible_inventory_item) { create(:inventory_item, enterprise: enterprise, variant: visible_variant, visible: true ) }

        context "finding variants that are not hidden from an enterprise's inventory" do
          context "when the enterprise given is nil" do
            let!(:variants) { Spree::Variant.not_hidden_for(nil) }

            it "returns an empty list" do
              expect(variants).to eq []
            end
          end

          context "when an enterprise is given" do
            let!(:variants) { Spree::Variant.not_hidden_for(enterprise) }

            it "lists any variants that are not listed as visible=false" do
              expect(variants).to include new_variant, visible_variant
              expect(variants).to_not include hidden_variant
            end

            context "when inventory items exist for other enterprises" do
              let(:other_enterprise) { create(:distributor_enterprise) }

              let!(:new_inventory_item) { create(:inventory_item, enterprise: other_enterprise, variant: new_variant, visible: true ) }
              let!(:hidden_inventory_item2) { create(:inventory_item, enterprise: other_enterprise, variant: visible_variant, visible: false ) }
              let!(:visible_inventory_item2) { create(:inventory_item, enterprise: other_enterprise, variant: hidden_variant, visible: true ) }

              it "lists any variants that are not listed as visible=false only for the relevant enterprise" do
                expect(variants).to include new_variant, visible_variant
                expect(variants).to_not include hidden_variant
              end
            end
          end
        end

        context "finding variants that are visible in an enterprise's inventory" do
          let!(:variants) { Spree::Variant.visible_for(enterprise) }

          it "lists any variants that are listed as visible=true" do
            expect(variants).to include visible_variant
            expect(variants).to_not include new_variant, hidden_variant
          end
        end
      end

      describe 'stockable_by' do
        let(:shop) { create(:distributor_enterprise) }
        let(:add_to_oc_producer) { create(:supplier_enterprise) }
        let(:other_producer) { create(:supplier_enterprise) }
        let!(:v1) { create(:variant, product: create(:simple_product, supplier: shop ) ) }
        let!(:v2) { create(:variant, product: create(:simple_product, supplier: add_to_oc_producer ) ) }
        let!(:v3) { create(:variant, product: create(:simple_product, supplier: other_producer ) ) }

        before do
          create(:enterprise_relationship, parent: add_to_oc_producer, child: shop, permissions_list: [:add_to_order_cycle])
          create(:enterprise_relationship, parent: other_producer, child: shop, permissions_list: [:manage_products])
        end

        it 'shows variants produced by the enterprise and any producers granting P-OC' do
          stockable_variants = Spree::Variant.stockable_by(shop)
          expect(stockable_variants).to include v1, v2
          expect(stockable_variants).to_not include v3
        end
      end
    end

    describe "callbacks" do
      let(:variant) { create(:variant) }

      it "refreshes the products cache on save" do
        expect(OpenFoodNetwork::ProductsCache).to receive(:variant_changed).with(variant)
        variant.sku = 'abc123'
        variant.save
      end

      it "refreshes the products cache on destroy" do
        expect(OpenFoodNetwork::ProductsCache).to receive(:variant_destroyed).with(variant)
        variant.destroy
      end

      context "when it is the master variant" do
        let(:product) { create(:simple_product) }
        let(:master) { product.master }

        it "refreshes the products cache for the entire product on save" do
          expect(OpenFoodNetwork::ProductsCache).to receive(:product_changed).with(product)
          expect(OpenFoodNetwork::ProductsCache).to receive(:variant_changed).never
          master.sku = 'abc123'
          master.save
        end

        it "refreshes the products cache for the entire product on destroy" do
          # Does this ever happen?
          expect(OpenFoodNetwork::ProductsCache).to receive(:product_changed).with(product)
          expect(OpenFoodNetwork::ProductsCache).to receive(:variant_destroyed).never
          master.destroy
        end
      end
    end

    describe "indexing variants by id" do
      let!(:v1) { create(:variant) }
      let!(:v2) { create(:variant) }
      let!(:v3) { create(:variant) }

      it "indexes variants by id" do
        Variant.where(id: [v1, v2, v3]).indexed.should ==
          {v1.id => v1, v2.id => v2, v3.id => v3}
      end
    end

    describe "generating the product and variant name" do
      let(:v) { Variant.new }
      let(:p) { double(:product, name: 'product') }
      before { allow(v).to receive(:product) { p } }

      context "when full_name starts with the product name" do
        before { allow(v).to receive(:full_name) { p.name + " - something" } }

        it "does not show the product name twice" do
          v.product_and_full_name.should == 'product - something'
        end
      end

      context "when full_name does not start with the product name" do
        before { allow(v).to receive(:full_name) { "display_name (unit)" } }

        it "prepends the product name to the full name" do
          v.product_and_full_name.should == 'product - display_name (unit)'
        end
      end
    end

    describe "calculating the price with enterprise fees" do
      it "returns the price plus the fees" do
        distributor = double(:distributor)
        order_cycle = double(:order_cycle)

        variant = Variant.new price: 100
        variant.should_receive(:fees_for).with(distributor, order_cycle) { 23 }
        variant.price_with_fees(distributor, order_cycle).should == 123
      end
    end


    describe "calculating the fees" do
      it "delegates to EnterpriseFeeCalculator" do
        distributor = double(:distributor)
        order_cycle = double(:order_cycle)
        variant = Variant.new

        OpenFoodNetwork::EnterpriseFeeCalculator.any_instance.should_receive(:fees_for).with(variant) { 23 }

        variant.fees_for(distributor, order_cycle).should == 23
      end
    end


    describe "calculating fees broken down by fee type" do
      it "delegates to EnterpriseFeeCalculator" do
        distributor = double(:distributor)
        order_cycle = double(:order_cycle)
        variant = Variant.new
        fees = double(:fees)

        OpenFoodNetwork::EnterpriseFeeCalculator.any_instance.should_receive(:fees_by_type_for).with(variant) { fees }

        variant.fees_by_type_for(distributor, order_cycle).should == fees
      end
    end


    context "when the product has variants" do
      let!(:product) { create(:simple_product) }
      let!(:variant) { create(:variant, product: product) }

      %w(weight volume).each do |unit|
        context "when the product's unit is #{unit}" do
          before do
            product.update_attribute :variant_unit, unit
            product.reload
          end

          it "is valid when unit value is set and unit description is not" do
            variant.unit_value = 1
            variant.unit_description = nil
            variant.should be_valid
          end

          it "is invalid when unit value is not set" do
            variant.unit_value = nil
            variant.should_not be_valid
          end

          it "has a valid master variant" do
            product.master.should be_valid
          end
        end
      end

      context "when the product's unit is items" do
        before do
          product.update_attribute :variant_unit, 'items'
          product.reload
        end

        it "is valid with only unit value set" do
          variant.unit_value = 1
          variant.unit_description = nil
          variant.should be_valid
        end

        it "is valid with only unit description set" do
          variant.unit_value = nil
          variant.unit_description = 'Medium'
          variant.should be_valid
        end

        it "is invalid when neither unit value nor unit description are set" do
          variant.unit_value = nil
          variant.unit_description = nil
          variant.should_not be_valid
        end

        it "has a valid master variant" do
          product.master.should be_valid
        end
      end
    end

    describe "unit value/description" do
      describe "generating the full name" do
        let(:v) { Variant.new }

        before do
          v.stub(:display_name) { 'display_name' }
          v.stub(:unit_to_display) { 'unit_to_display' }
        end

        it "returns unit_to_display when display_name is blank" do
          v.stub(:display_name) { '' }
          v.full_name.should == 'unit_to_display'
        end

        it "returns display_name when it contains unit_to_display" do
          v.stub(:display_name) { 'DiSpLaY_name' }
          v.stub(:unit_to_display) { 'name' }
          v.full_name.should == 'DiSpLaY_name'
        end

        it "returns unit_to_display when it contains display_name" do
          v.stub(:display_name) { '_to_' }
          v.stub(:unit_to_display) { 'unit_TO_display' }
          v.full_name.should == 'unit_TO_display'
        end

        it "returns a combination otherwise" do
          v.stub(:display_name) { 'display_name' }
          v.stub(:unit_to_display) { 'unit_to_display' }
          v.full_name.should == 'display_name (unit_to_display)'
        end

        it "is resilient to regex chars" do
          v = Variant.new display_name: ")))"
          v.stub(:unit_to_display) { ")))" }
          v.full_name.should == ")))"
        end
      end

      describe "getting name for display" do
        it "returns display_name if present" do
          v = create(:variant, display_name: "foo")
          v.name_to_display.should == "foo"
        end

        it "returns product name if display_name is empty" do
          v = create(:variant, product: create(:product))
          v.name_to_display.should == v.product.name
          v1 = create(:variant, display_name: "", product: create(:product))
          v1.name_to_display.should == v1.product.name
        end
      end

      describe "getting unit for display" do
        it "returns display_as if present" do
          v = create(:variant, display_as: "foo")
          v.unit_to_display.should == "foo"
        end

        it "returns options_text if display_as is blank" do
          v = create(:variant)
          v1 = create(:variant, display_as: "")
          v.stub(:options_text).and_return "ponies"
          v1.stub(:options_text).and_return "ponies"
          v.unit_to_display.should == "ponies"
          v1.unit_to_display.should == "ponies"
        end
      end

      describe "setting the variant's weight from the unit value" do
        it "sets the variant's weight when unit is weight" do
          p = create(:simple_product, variant_unit: 'volume')
          v = create(:variant, product: p, weight: nil)

          p.update_attributes! variant_unit: 'weight', variant_unit_scale: 1
          v.update_attributes! unit_value: 10, unit_description: 'foo'

          v.reload.weight.should == 0.01
        end

        it "does nothing when unit is not weight" do
          p = create(:simple_product, variant_unit: 'volume')
          v = create(:variant, product: p, weight: 123)

          p.update_attributes! variant_unit: 'volume', variant_unit_scale: 1
          v.update_attributes! unit_value: 10, unit_description: 'foo'

          v.reload.weight.should == 123
        end

        it "does nothing when unit_value is not set" do
          p = create(:simple_product, variant_unit: 'volume')
          v = create(:variant, product: p, weight: 123)

          p.update_attributes! variant_unit: 'weight', variant_unit_scale: 1

          # Although invalid, this calls the before_validation callback, which would
          # error if not handling unit_value == nil case
          v.update_attributes(unit_value: nil, unit_description: 'foo').should be false

          v.reload.weight.should == 123
        end
      end

      context "when the variant already has a value set (and all required option values do not exist)" do
        let!(:p) { create(:simple_product, variant_unit: 'weight', variant_unit_scale: 1) }
        let!(:v) { create(:variant, product: p, unit_value: 5, unit_description: 'bar') }

        it "removes the old option value and assigns the new one" do
          ov_orig = v.option_values.last

          expect {
            v.update_attributes!(unit_value: 10, unit_description: 'foo')
          }.to change(Spree::OptionValue, :count).by(1)

          v.option_values.should_not include ov_orig
        end
      end

      context "when the variant already has a value set (and all required option values exist)" do
        let!(:p0) { create(:simple_product, variant_unit: 'weight', variant_unit_scale: 1) }
        let!(:v0) { create(:variant, product: p0, unit_value: 10, unit_description: 'foo') }

        let!(:p) { create(:simple_product, variant_unit: 'weight', variant_unit_scale: 1) }
        let!(:v) { create(:variant, product: p, unit_value: 5, unit_description: 'bar') }

        it "removes the old option value and assigns the new one" do
          ov_orig = v.option_values.last
          ov_new  = v0.option_values.last

          expect {
            v.update_attributes!(unit_value: 10, unit_description: 'foo')
          }.to change(Spree::OptionValue, :count).by(0)

          v.option_values.should_not include ov_orig
          v.option_values.should     include ov_new
        end
      end

      context "when the variant does not have a display_as value set" do
        let!(:p) { create(:simple_product, variant_unit: 'weight', variant_unit_scale: 1) }
        let!(:v) { create(:variant, product: p, unit_value: 5, unit_description: 'bar', display_as: '') }

        it "requests the name of the new option_value from OptionValueName" do
          OpenFoodNetwork::OptionValueNamer.any_instance.should_receive(:name).exactly(1).times.and_call_original
          v.update_attributes(unit_value: 10, unit_description: 'foo')
          ov = v.option_values.last
          ov.name.should == "10g foo"
        end
      end

      context "when the variant has a display_as value set" do
        let!(:p) { create(:simple_product, variant_unit: 'weight', variant_unit_scale: 1) }
        let!(:v) { create(:variant, product: p, unit_value: 5, unit_description: 'bar', display_as: 'FOOS!') }

        it "does not request the name of the new option_value from OptionValueName" do
          OpenFoodNetwork::OptionValueNamer.any_instance.should_not_receive(:name)
          v.update_attributes!(unit_value: 10, unit_description: 'foo')
          ov = v.option_values.last
          ov.name.should == "FOOS!"
        end
      end
    end

    describe "deleting unit option values" do
      before do
        p = create(:simple_product, variant_unit: 'weight', variant_unit_scale: 1)
        ot = Spree::OptionType.find_by_name 'unit_weight'
        @v = create(:variant, product: p)
      end

      it "removes option value associations for unit option types" do
        expect {
          @v.delete_unit_option_values
        }.to change(@v.option_values, :count).by(-1)
      end

      it "does not delete option values" do
        expect {
          @v.delete_unit_option_values
        }.to change(Spree::OptionValue, :count).by(0)
      end
    end

    context "extends LocalizedNumber" do
      subject! { build(:variant) }

      it_behaves_like "a model using the LocalizedNumber module", [:price, :cost_price, :weight]
    end
  end

  describe "destruction" do
    it "destroys exchange variants" do
      v = create(:variant)
      e = create(:exchange, variants: [v])

      v.destroy
      e.reload.variant_ids.should be_empty
    end

    context "as the last variant of a product" do
      let!(:extra_variant) { create(:variant) }
      let!(:product) { extra_variant.product }
      let!(:first_variant) { product.variants.first }

      before { product.reload }

      it "cannot be deleted" do
        expect(product.variants.length).to eq 2
        expect(extra_variant.delete).to eq extra_variant
        expect(product.variants(:reload).length).to eq 1
        expect(first_variant.delete).to be false
        expect(product.variants(:reload).length).to eq 1
        expect(first_variant.errors[:product]).to include "must have at least one variant"
      end
    end
  end
end
