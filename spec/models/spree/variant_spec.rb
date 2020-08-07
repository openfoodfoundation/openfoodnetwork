require 'spec_helper'
require 'variant_units/option_value_namer'

module Spree
  describe Variant do
    let!(:variant) { create(:variant) }

    context "validations" do
      it "should validate price is greater than 0" do
        variant.price = -1
        expect(variant).to be_invalid
      end

      it "should validate price is 0" do
        variant.price = 0
        expect(variant).to be_valid
      end
    end

    context "after create" do
      let!(:product) { create(:product) }

      it "propagate to stock items" do
        Spree::StockLocation.any_instance.should_receive(:propagate_variant)
        product.variants.create(name: "Foobar")
      end

      context "stock location has disable propagate all variants" do
        before { Spree::StockLocation.any_instance.stub(propagate_all_variants?: false) }

        it "propagate to stock items" do
          Spree::StockLocation.any_instance.should_not_receive(:propagate_variant)
          product.variants.create(name: "Foobar")
        end
      end
    end

    context "product has other variants" do
      describe "option value accessors" do
        before {
          @multi_variant = FactoryGirl.create :variant, product: variant.product
          variant.product.reload
        }

        let(:multi_variant) { @multi_variant }

        it "should set option value" do
          expect(multi_variant.option_value('media_type')).to be_nil

          multi_variant.set_option_value('media_type', 'DVD')
          expect(multi_variant.option_value('media_type')).to == 'DVD'

          multi_variant.set_option_value('media_type', 'CD')
          expect(multi_variant.option_value('media_type')).to == 'CD'
        end

        it "should not duplicate associated option values when set multiple times" do
          multi_variant.set_option_value('media_type', 'CD')

          expect {
            multi_variant.set_option_value('media_type', 'DVD')
          }.to_not change(multi_variant.option_values, :count)

          expect {
            multi_variant.set_option_value('coolness_type', 'awesome')
          }.to change(multi_variant.option_values, :count).by(1)
        end
      end

      context "product has other variants" do
        describe "option value accessors" do
          before {
            @multi_variant = create(:variant, product: variant.product)
            variant.product.reload
          }

          let(:multi_variant) { @multi_variant }

          it "should set option value" do
            expect(multi_variant.option_value('media_type')).to be_nil

            multi_variant.set_option_value('media_type', 'DVD')
            expect(multi_variant.option_value('media_type')).to == 'DVD'

            multi_variant.set_option_value('media_type', 'CD')
            expect(multi_variant.option_value('media_type')).to == 'CD'
          end

          it "should not duplicate associated option values when set multiple times" do
            multi_variant.set_option_value('media_type', 'CD')

            expect {
              multi_variant.set_option_value('media_type', 'DVD')
            }.to_not change(multi_variant.option_values, :count)

            expect {
              multi_variant.set_option_value('coolness_type', 'awesome')
            }.to change(multi_variant.option_values, :count).by(1)
          end
        end
      end
    end

    context "price parsing" do
      before(:each) do
        I18n.locale = I18n.default_locale
        I18n.backend.store_translations(:de, { number: { currency: { format: { delimiter: '.', separator: ',' } } } })
      end

      after do
        I18n.locale = I18n.default_locale
      end

      context "price=" do
        context "with decimal point" do
          it "captures the proper amount for a formatted price" do
            variant.price = '1,599.99'
            expect(variant.price).to == 1599.99
          end
        end

        context "with decimal comma" do
          it "captures the proper amount for a formatted price" do
            I18n.locale = :de
            variant.price = '1.599,99'
            expect(variant.price).to == 1599.99
          end
        end

        context "with a numeric price" do
          it "uses the price as is" do
            I18n.locale = :de
            variant.price = 1599.99
            expect(variant.price).to == 1599.99
          end
        end
      end

      context "cost_price=" do
        context "with decimal point" do
          it "captures the proper amount for a formatted price" do
            variant.cost_price = '1,599.99'
            expect(variant.cost_price).to == 1599.99
          end
        end

        context "with decimal comma" do
          it "captures the proper amount for a formatted price" do
            I18n.locale = :de
            variant.cost_price = '1.599,99'
            expect(variant.cost_price).to == 1599.99
          end
        end

        context "with a numeric price" do
          it "uses the price as is" do
            I18n.locale = :de
            variant.cost_price = 1599.99
            expect(variant.cost_price).to == 1599.99
          end
        end
      end
    end

    context "#currency" do
      it "returns the globally configured currency" do
        expect(variant.currency).to == "USD"
      end
    end

    context "#display_amount" do
      it "returns a Spree::Money" do
        variant.price = 21.22
        expect(variant.display_amount.to_s).to == "$21.22"
      end
    end

    context "#cost_currency" do
      context "when cost currency is nil" do
        before { variant.cost_currency = nil }
        it "populates cost currency with the default value on save" do
          variant.save!
          expect(variant.cost_currency).to == "USD"
        end
      end
    end

    describe '.price_in' do
      before do
        variant.prices << create(:price, variant: variant, currency: "EUR", amount: 33.33)
      end
      subject { variant.price_in(currency).display_amount }

      context "when currency is not specified" do
        let(:currency) { nil }

        it "returns 0" do
          expect(subject.to_s).to == "$0.00"
        end
      end

      context "when currency is EUR" do
        let(:currency) { 'EUR' }

        it "returns the value in the EUR" do
          expect(subject.to_s).to == "€33.33"
        end
      end

      context "when currency is USD" do
        let(:currency) { 'USD' }

        it "returns the value in the USD" do
          expect(subject.to_s).to == "$19.99"
        end
      end
    end

    describe '.amount_in' do
      before do
        variant.prices << create(:price, variant: variant, currency: "EUR", amount: 33.33)
      end

      subject { variant.amount_in(currency) }

      context "when currency is not specified" do
        let(:currency) { nil }

        it "returns nil" do
          expect(subject).to be_nil
        end
      end

      context "when currency is EUR" do
        let(:currency) { 'EUR' }

        it "returns the value in the EUR" do
          expect(subject).to == 33.33
        end
      end

      context "when currency is USD" do
        let(:currency) { 'USD' }

        it "returns the value in the USD" do
          expect(subject).to == 19.99
        end
      end
    end

    # Regression test for #2432
    describe 'options_text' do
      before do
        option_type = double("OptionType", presentation: "Foo")
        option_values = [double("OptionValue", option_type: option_type, presentation: "bar")]
        variant.stub(:option_values).and_return(option_values)
      end

      it "orders options correctly" do
        variant.option_values.should_receive(:joins).with(:option_type).and_return(scope = double)
        scope.should_receive(:order).with('spree_option_types.position asc').and_return(variant.option_values)
        variant.options_text
      end
    end

    # Regression test for #2744
    describe "set_position" do
      it "sets variant position after creation" do
        variant = create(:variant)
        expect(variant.position).to_not be_nil
      end
    end

    describe '#in_stock?' do
      before do
        Spree::Config.track_inventory_levels = true
      end

      context 'when stock_items are not backorderable' do
        before do
          Spree::StockItem.any_instance.stub(backorderable: false)
        end

        context 'when stock_items in stock' do
          before do
            Spree::StockItem.any_instance.stub(count_on_hand: 10)
          end

          it 'returns true if stock_items in stock' do
            expect(variant.in_stock?).to be_truthy
          end
        end

        context 'when stock_items out of stock' do
          before do
            Spree::StockItem.any_instance.stub(backorderable: false)
            Spree::StockItem.any_instance.stub(count_on_hand: 0)
          end

          it 'return false if stock_items out of stock' do
            expect(variant.in_stock?).to be_falsy
          end
        end

        context 'when providing quantity param' do
          before do
            variant.stock_items.first.update_attribute(:count_on_hand, 10)
          end

          it 'returns correctt value' do
            expect(variant.in_stock?).to be_truthy
            expect(variant.in_stock?(2)).to be_truthy
            expect(variant.in_stock?(10)).to be_truthy
            expect(variant.in_stock?(11)).to be_falsy
          end
        end
      end

      context 'when stock_items are backorderable' do
        before do
          Spree::StockItem.any_instance.stub(backorderable: true)
        end

        context 'when stock_items out of stock' do
          before do
            Spree::StockItem.any_instance.stub(count_on_hand: 0)
          end

          it 'returns true if stock_items in stock' do
            expect(variant.in_stock?).to be_truthy
          end
        end
      end
    end

    describe '#total_on_hand' do
      it 'should be infinite if track_inventory_levels is false' do
        Spree::Config[:track_inventory_levels] = false
        expect(build(:variant).total_on_hand).to eql(Float::INFINITY)
      end

      it 'should match quantifier total_on_hand' do
        variant = build(:variant)
        expect(variant.total_on_hand).to eq(Spree::Stock::Quantifier.new(variant).total_on_hand)
      end
    end

    describe "double loading" do
      # app/models/spree/variant_decorator.rb  may be double-loaded in delayed job environment,
      # so we need to be able to do so without error.
      it "succeeds without error" do
        load "#{Rails.root}/app/models/spree/variant_decorator.rb"
      end
    end

    describe "scopes" do
      describe "finding variants in a distributor" do
        let!(:d1) { create(:distributor_enterprise) }
        let!(:d2) { create(:distributor_enterprise) }
        let!(:p1) { create(:simple_product) }
        let!(:p2) { create(:simple_product) }
        let!(:oc1) { create(:simple_order_cycle, distributors: [d1], variants: [p1.master]) }
        let!(:oc2) { create(:simple_order_cycle, distributors: [d2], variants: [p2.master]) }

        it "shows variants in an order cycle distribution" do
          expect(Variant.in_distributor(d1)).to eq([p1.master])
        end

        it "doesn't show duplicates" do
          oc_dup = create(:simple_order_cycle, distributors: [d1], variants: [p1.master])
          expect(Variant.in_distributor(d1)).to eq([p1.master])
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
          expect(Variant.in_order_cycle(oc1)).to eq([p1.master])
        end

        it "doesn't show duplicates" do
          ex = create(:exchange, order_cycle: oc1, sender: oc1.coordinator, receiver: d2)
          ex.variants << p1.master

          expect(Variant.in_order_cycle(oc1)).to eq([p1.master])
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

        let!(:ex_in) {
          create(:exchange, order_cycle: oc, sender: s, receiver: oc.coordinator,
                            incoming: true, variants: [v1, v2])
        }
        let!(:ex_out1) {
          create(:exchange, order_cycle: oc, sender: oc.coordinator, receiver: d1,
                            incoming: false, variants: [v1])
        }
        let!(:ex_out2) {
          create(:exchange, order_cycle: oc, sender: oc.coordinator, receiver: d2,
                            incoming: false, variants: [v2])
        }

        it "returns variants in the order cycle and distributor" do
          expect(p1.variants.for_distribution(oc, d1)).to eq([v1])
          expect(p2.variants.for_distribution(oc, d2)).to eq([v2])
        end

        it "does not return variants in the order cycle but not the distributor" do
          expect(p1.variants.for_distribution(oc, d2)).to be_empty
          expect(p2.variants.for_distribution(oc, d1)).to be_empty
        end

        it "does not return variants not in the order cycle" do
          expect(p_external.variants.for_distribution(oc, d1)).to be_empty
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

    describe "indexing variants by id" do
      let!(:v1) { create(:variant) }
      let!(:v2) { create(:variant) }
      let!(:v3) { create(:variant) }

      it "indexes variants by id" do
        expect(Variant.where(id: [v1, v2, v3]).indexed).to eq(
          v1.id => v1, v2.id => v2, v3.id => v3
        )
      end
    end

    describe "generating the product and variant name" do
      let(:v) { Variant.new }
      let(:p) { double(:product, name: 'product') }
      before { allow(v).to receive(:product) { p } }

      context "when full_name starts with the product name" do
        before { allow(v).to receive(:full_name) { p.name + " - something" } }

        it "does not show the product name twice" do
          expect(v.product_and_full_name).to eq('product - something')
        end
      end

      context "when full_name does not start with the product name" do
        before { allow(v).to receive(:full_name) { "display_name (unit)" } }

        it "prepends the product name to the full name" do
          expect(v.product_and_full_name).to eq('product - display_name (unit)')
        end
      end
    end

    describe "calculating the price with enterprise fees" do
      it "returns the price plus the fees" do
        distributor = double(:distributor)
        order_cycle = double(:order_cycle)

        variant = Variant.new price: 100
        expect(variant).to receive(:fees_for).with(distributor, order_cycle) { 23 }
        expect(variant.price_with_fees(distributor, order_cycle)).to eq(123)
      end
    end

    describe "calculating the fees" do
      it "delegates to EnterpriseFeeCalculator" do
        distributor = double(:distributor)
        order_cycle = double(:order_cycle)
        variant = Variant.new

        expect_any_instance_of(OpenFoodNetwork::EnterpriseFeeCalculator).to receive(:fees_for).with(variant) { 23 }

        expect(variant.fees_for(distributor, order_cycle)).to eq(23)
      end
    end

    describe "calculating fees broken down by fee type" do
      it "delegates to EnterpriseFeeCalculator" do
        distributor = double(:distributor)
        order_cycle = double(:order_cycle)
        variant = Variant.new
        fees = double(:fees)

        expect_any_instance_of(OpenFoodNetwork::EnterpriseFeeCalculator).to receive(:fees_by_type_for).with(variant) { fees }

        expect(variant.fees_by_type_for(distributor, order_cycle)).to eq(fees)
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
            expect(variant).to be_valid
          end

          it "is invalid when unit value is not set" do
            variant.unit_value = nil
            expect(variant).not_to be_valid
          end

          it "has a valid master variant" do
            expect(product.master).to be_valid
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
          expect(variant).to be_valid
        end

        it "is valid with only unit description set" do
          variant.unit_value = nil
          variant.unit_description = 'Medium'
          expect(variant).to be_valid
        end

        it "is invalid when neither unit value nor unit description are set" do
          variant.unit_value = nil
          variant.unit_description = nil
          expect(variant).not_to be_valid
        end

        it "has a valid master variant" do
          expect(product.master).to be_valid
        end
      end
    end

    describe "unit value/description" do
      describe "generating the full name" do
        let(:v) { Variant.new }

        before do
          allow(v).to receive(:display_name) { 'display_name' }
          allow(v).to receive(:unit_to_display) { 'unit_to_display' }
        end

        it "returns unit_to_display when display_name is blank" do
          allow(v).to receive(:display_name) { '' }
          expect(v.full_name).to eq('unit_to_display')
        end

        it "returns display_name when it contains unit_to_display" do
          allow(v).to receive(:display_name) { 'DiSpLaY_name' }
          allow(v).to receive(:unit_to_display) { 'name' }
          expect(v.full_name).to eq('DiSpLaY_name')
        end

        it "returns unit_to_display when it contains display_name" do
          allow(v).to receive(:display_name) { '_to_' }
          allow(v).to receive(:unit_to_display) { 'unit_TO_display' }
          expect(v.full_name).to eq('unit_TO_display')
        end

        it "returns a combination otherwise" do
          allow(v).to receive(:display_name) { 'display_name' }
          allow(v).to receive(:unit_to_display) { 'unit_to_display' }
          expect(v.full_name).to eq('display_name (unit_to_display)')
        end

        it "is resilient to regex chars" do
          v = Variant.new display_name: ")))"
          allow(v).to receive(:unit_to_display) { ")))" }
          expect(v.full_name).to eq(")))")
        end
      end

      describe "getting name for display" do
        it "returns display_name if present" do
          v = create(:variant, display_name: "foo")
          expect(v.name_to_display).to eq("foo")
        end

        it "returns product name if display_name is empty" do
          v = create(:variant, product: create(:product))
          expect(v.name_to_display).to eq(v.product.name)
          v1 = create(:variant, display_name: "", product: create(:product))
          expect(v1.name_to_display).to eq(v1.product.name)
        end
      end

      describe "getting unit for display" do
        it "returns display_as if present" do
          v = create(:variant, display_as: "foo")
          expect(v.unit_to_display).to eq("foo")
        end

        it "returns options_text if display_as is blank" do
          v = create(:variant)
          v1 = create(:variant, display_as: "")
          allow(v).to receive(:options_text).and_return "ponies"
          allow(v1).to receive(:options_text).and_return "ponies"
          expect(v.unit_to_display).to eq("ponies")
          expect(v1.unit_to_display).to eq("ponies")
        end
      end

      describe "setting the variant's weight from the unit value" do
        it "sets the variant's weight when unit is weight" do
          p = create(:simple_product, variant_unit: 'volume')
          v = create(:variant, product: p, weight: nil)

          p.update! variant_unit: 'weight', variant_unit_scale: 1
          v.update! unit_value: 10, unit_description: 'foo'

          expect(v.reload.weight).to eq(0.01)
        end

        it "does nothing when unit is not weight" do
          p = create(:simple_product, variant_unit: 'volume')
          v = create(:variant, product: p, weight: 123)

          p.update! variant_unit: 'volume', variant_unit_scale: 1
          v.update! unit_value: 10, unit_description: 'foo'

          expect(v.reload.weight).to eq(123)
        end

        it "does nothing when unit_value is not set" do
          p = create(:simple_product, variant_unit: 'volume')
          v = create(:variant, product: p, weight: 123)

          p.update! variant_unit: 'weight', variant_unit_scale: 1

          # Although invalid, this calls the before_validation callback, which would
          # error if not handling unit_value == nil case
          expect(v.update(unit_value: nil, unit_description: 'foo')).to be false

          expect(v.reload.weight).to eq(123)
        end
      end

      context "when the variant already has a value set (and all required option values do not exist)" do
        let!(:p) { create(:simple_product, variant_unit: 'weight', variant_unit_scale: 1) }
        let!(:v) { create(:variant, product: p, unit_value: 5, unit_description: 'bar') }

        it "removes the old option value and assigns the new one" do
          ov_orig = v.option_values.last

          expect {
            v.update!(unit_value: 10, unit_description: 'foo')
          }.to change(Spree::OptionValue, :count).by(1)

          expect(v.option_values).not_to include ov_orig
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
            v.update!(unit_value: 10, unit_description: 'foo')
          }.to change(Spree::OptionValue, :count).by(0)

          expect(v.option_values).not_to include ov_orig
          expect(v.option_values).to     include ov_new
        end
      end

      context "when the variant does not have a display_as value set" do
        let!(:p) { create(:simple_product, variant_unit: 'weight', variant_unit_scale: 1) }
        let!(:v) { create(:variant, product: p, unit_value: 5, unit_description: 'bar', display_as: '') }

        it "requests the name of the new option_value from OptionValueName" do
          expect_any_instance_of(VariantUnits::OptionValueNamer).to receive(:name).exactly(1).times.and_call_original
          v.update(unit_value: 10, unit_description: 'foo')
          ov = v.option_values.last
          expect(ov.name).to eq("10g foo")
        end
      end

      context "when the variant has a display_as value set" do
        let!(:p) { create(:simple_product, variant_unit: 'weight', variant_unit_scale: 1) }
        let!(:v) { create(:variant, product: p, unit_value: 5, unit_description: 'bar', display_as: 'FOOS!') }

        it "does not request the name of the new option_value from OptionValueName" do
          expect_any_instance_of(VariantUnits::OptionValueNamer).not_to receive(:name)
          v.update!(unit_value: 10, unit_description: 'foo')
          ov = v.option_values.last
          expect(ov.name).to eq("FOOS!")
        end
      end
    end

    describe "deleting unit option values" do
      before do
        p = create(:simple_product, variant_unit: 'weight', variant_unit_scale: 1)
        ot = Spree::OptionType.find_by name: 'unit_weight'
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

    context "in a circular order cycle setup" do
      let(:enterprise1) { create(:distributor_enterprise, is_primary_producer: true) }
      let(:enterprise2) { create(:distributor_enterprise, is_primary_producer: true) }
      let(:variant1) { create(:variant) }
      let(:variant2) { create(:variant) }
      let!(:order_cycle) do
        enterprise1.supplied_products << variant1.product
        enterprise2.supplied_products << variant2.product
        create(
          :simple_order_cycle,
          coordinator: enterprise1,
          suppliers: [enterprise1, enterprise2],
          distributors: [enterprise1, enterprise2],
          variants: [variant1, variant2]
        )
      end

      it "saves without infinite loop" do
        expect(variant1.update(cost_price: 1)).to be_truthy
      end
    end
  end

  describe "destruction" do
    it "destroys exchange variants" do
      v = create(:variant)
      e = create(:exchange, variants: [v])

      v.destroy
      expect(e.reload.variant_ids).to be_empty
    end
  end
end
