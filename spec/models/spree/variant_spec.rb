# frozen_string_literal: false

require 'spree/localized_number'

RSpec.describe Spree::Variant do
  subject(:variant) { build(:variant) }

  it { is_expected.to have_many :semantic_links }
  it { is_expected.to belong_to(:product).required }
  it { is_expected.to belong_to(:supplier).required }
  it { is_expected.to have_many(:inventory_units) }
  it { is_expected.to have_many(:line_items) }
  it { is_expected.to have_many(:stock_items) }
  it { is_expected.to have_many(:images) }
  it { is_expected.to have_one(:default_price) }
  it { is_expected.to have_many(:prices) }
  it { is_expected.to have_many(:exchange_variants) }
  it { is_expected.to have_many(:exchanges).through(:exchange_variants) }
  it { is_expected.to have_many(:variant_overrides) }
  it { is_expected.to have_many(:inventory_items) }
  it { is_expected.to have_many(:supplier_properties).through(:supplier) }

  describe "shipping category" do
    it "sets a shipping category if none provided" do
      variant = build(:variant, shipping_category: nil)

      expect(variant).to be_valid
      expect(variant.shipping_category).not_to be_nil
    end
  end

  describe "supplier properties" do
    subject { create(:variant) }

    it "has no supplier properties to start with" do
      expect(subject.supplier_properties).to eq []
    end

    it "includes the supplier's properties" do
      subject.supplier.set_producer_property("certified", "yes")
      expect(subject.supplier_properties.map(&:presentation)).to eq ["certified"]
    end
  end

  describe "validations" do
    describe "variant_unit" do
      subject(:variant) { build(:variant) }

      it { is_expected.to validate_presence_of :variant_unit }

      context "when the unit is items" do
        subject(:variant) { build(:variant, variant_unit: "items", variant_unit_name: "box") }

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

        it "sets unit_value to 1.0 before validation if it's nil" do
          variant.unit_value = nil
          variant.unit_description = nil
          expect(variant).to be_valid
          expect(variant.unit_value).to eq 1.0
        end
      end

      context "when the product's unit is non-weight" do
        subject(:variant) { build(:variant, variant_unit: "volume") }

        it "sets weight to decimal before save if it's integer" do
          variant.weight = 1
          variant.save!
          expect(variant.weight).to eq 1.0
        end

        it "sets weight to 0.0 before save if it's nil" do
          variant.weight = nil
          variant.save!
          expect(variant.weight).to eq 0.0
        end

        it "sets weight to 0.0 if input is a non numerical string" do
          variant.weight = "BANANAS!"
          variant.save!
          expect(variant.weight).to eq 0.0
        end

        it "sets weight to correct decimal value if input is numerical string" do
          variant.weight = "2"
          variant.save!
          expect(variant.weight).to eq 2.0
        end
      end
    end

    describe "price" do
      it { is_expected.to validate_presence_of :price }

      it "should validate price is greater than 0" do
        variant.price = -1
        expect(variant).not_to be_valid
      end

      it "should validate price is 0" do
        variant.price = 0
        expect(variant).to be_valid
      end

      it "should validate unit_value is greater than 0" do
        variant.unit_value = 0

        expect(variant).not_to be_valid
      end
    end

    describe "unit_value" do
      subject(:variant) { build(:variant, variant_unit: "item", unit_value: "") }

      it { is_expected.not_to validate_presence_of(:unit_value) }

      %w(weight volume).each do |unit|
        context "when variant_unit is #{unit}" do
          subject(:variant) { build(:variant, variant_unit: unit) }

          it { is_expected.to validate_presence_of(:unit_value) }
          it { is_expected.to validate_numericality_of(:unit_value).is_greater_than(0) }
        end
      end
    end

    describe "unit_description" do
      subject(:variant) { build(:variant) }

      it { expect(variant).to be_valid }
      it { is_expected.not_to validate_presence_of(:unit_description) }

      context "when variant_unit is set and unit_value is nil" do
        subject(:variant) {
          build(:variant, variant_unit: "item", unit_value: nil, unit_description: "box")
        }

        it { is_expected.to validate_presence_of(:unit_description) }
      end
    end

    describe "variant_unit_scale" do
      subject(:variant) { build(:variant, variant_unit: "box") }

      it { is_expected.not_to validate_presence_of :variant_unit_scale }

      %w(weight volume).each do |unit|
        context "when variant_unit is #{unit}" do
          subject(:variant) { build(:variant, variant_unit: unit, variant_unit_scale: 1.0) }

          it { is_expected.to validate_presence_of :variant_unit_scale }
        end
      end
    end

    describe "variant_unit_name" do
      subject(:variant) { build(:variant) }

      it { is_expected.not_to validate_presence_of :variant_unit_name }

      context "when variant_unit is items" do
        subject(:variant) { build(:variant, variant_unit: "items") }

        it { is_expected.to validate_presence_of :variant_unit_name }
      end
    end

    describe "variant_unit_scale" do
      subject(:variant) { build(:variant, variant_unit: "box") }

      it { is_expected.not_to validate_presence_of :variant_unit_scale }

      %w(weight volume).each do |unit|
        context "when variant_unit is #{unit}" do
          subject(:variant) { build(:variant, variant_unit: unit, variant_unit_scale: 1.0) }

          it { is_expected.to validate_presence_of :variant_unit_scale }
        end
      end
    end

    describe "variant_unit_name" do
      subject(:variant) { build(:variant) }

      it { is_expected.not_to validate_presence_of :variant_unit_name }

      context "when variant_unit is items" do
        subject(:variant) { build(:variant, variant_unit: "items") }

        it { is_expected.to validate_presence_of :variant_unit_name }
      end
    end

    describe "tax category" do
      # `build_stubbed` avoids creating a tax category in the database.
      subject(:variant) { build_stubbed(:variant) }

      it "is valid when empty by default" do
        expect(variant.tax_category).to eq nil
        expect(variant).to be_valid
      end

      it "loads the default tax category" do
        default = create(:tax_category, is_default: true)

        expect(variant.tax_category).to eq default
        expect {
          variant.tax_category = nil
        }.not_to change {
          variant.tax_category
        }
        expect(variant).to be_valid
      end

      it "doesn't load any tax category" do
        non_default = create(:tax_category, is_default: false)
        expect(variant.tax_category).to eq nil
      end

      context "when a tax category is required" do
        before { Spree::Config.products_require_tax_category = true }

        it { is_expected.to validate_presence_of :tax_category }
      end
    end
  end

  describe "#changed?" do
    subject(:variant) { create(:variant) }

    it { is_expected.not_to be_changed }

    it "is changed when basic fields are changed" do
      subject.display_name = "blah"
      expect(subject).to be_changed
    end

    describe "default_price" do
      it "price" do
        subject.price = 100
        expect(subject).to be_changed
      end
      it "currency" do
        subject.currency = "USD"
        expect(subject).to be_changed
      end
    end
  end

  context "price parsing" do
    context "price=" do
      context "with decimal point" do
        it "captures the proper amount for a formatted price" do
          variant.price = '1,599.99'
          expect(variant.price).to eq 1599.99
        end
      end

      context "with decimal comma" do
        it "captures the proper amount for a formatted price" do
          I18n.with_locale(:es) do
            variant.price = '1.599,99'
            expect(variant.price).to eq 1599.99
          end
        end
      end

      context "with a numeric price" do
        it "uses the price as is" do
          I18n.with_locale(:es) do
            variant.price = 1599.99
            expect(variant.price).to eq 1599.99
          end
        end
      end
    end
  end

  context "#currency" do
    it "returns the globally configured currency" do
      variant.save!
      expect(variant.currency).to eq "AUD"
    end
  end

  context "#display_amount" do
    it "returns a Spree::Money" do
      variant.price = 21.22
      expect(variant.display_amount.to_s).to eq "$21.22"
    end
  end

  context "#cost_currency" do
    context "when cost currency is nil" do
      before { variant.cost_currency = nil }

      it "populates cost currency with the default value on save" do
        variant.save!
        expect(variant.cost_currency).to eq "AUD"
      end
    end
  end

  describe '.price_in' do
    before do
      variant.prices << create(:price, variant:, currency: "EUR", amount: 33.33)
    end
    subject { variant.price_in(currency).display_amount }

    context "when currency is not specified" do
      let(:currency) { nil }

      it "returns 0" do
        expect(subject.to_s).to eq "$0.00"
      end
    end

    context "when currency is EUR" do
      let(:currency) { 'EUR' }

      it "returns the value in EUR" do
        expect(subject.to_s).to eq "€33.33"
      end
    end

    context "when currency is AUD" do
      let(:currency) { 'AUD' }

      it "returns the value in AUD" do
        expect(subject.to_s).to eq "$19.99"
      end
    end
  end

  describe '.amount_in' do
    before do
      variant.prices << create(:price, variant:, currency: "EUR", amount: 33.33)
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

      it "returns the value in EUR" do
        expect(subject).to eq 33.33
      end
    end

    context "when currency is AUD" do
      let(:currency) { 'AUD' }

      it "returns the value in AUD" do
        expect(subject).to eq 19.99
      end
    end
  end

  describe '#in_stock?' do
    # Stock data can only be stored against a persisted variant.
    subject(:variant) { create(:variant) }

    context 'when stock_items are not backorderable' do
      before do
        allow_any_instance_of(Spree::StockItem).to receive_messages(backorderable: false)
      end

      context 'when stock_items in stock' do
        before do
          allow_any_instance_of(Spree::StockItem).to receive_messages(count_on_hand: 10)
        end

        it 'returns true if stock_items in stock' do
          expect(variant.in_stock?).to be_truthy
        end
      end

      context 'when stock_items out of stock' do
        before do
          allow_any_instance_of(Spree::StockItem).to receive_messages(backorderable: false)
          allow_any_instance_of(Spree::Stock::Quantifier).to receive_messages(total_on_hand: 0)
        end

        it 'return false if stock_items out of stock' do
          expect(variant.in_stock?).to be_falsy
        end
      end

      context 'when providing quantity param' do
        before do
          variant.stock_items.first.update_attribute(:count_on_hand, 10)
        end

        it 'returns correct value' do
          expect(variant.in_stock?).to be_truthy
          expect(variant.in_stock?(2)).to be_truthy
          expect(variant.in_stock?(10)).to be_truthy
          expect(variant.in_stock?(11)).to be_falsy
        end
      end
    end

    context 'when stock_items are backorderable' do
      before do
        allow_any_instance_of(Spree::StockItem).to receive_messages(backorderable?: true)
      end

      context 'when stock_items out of stock' do
        before do
          allow_any_instance_of(Spree::StockItem).to receive_messages(count_on_hand: 0)
        end

        it 'returns true if stock_items in stock' do
          expect(variant.in_stock?).to be_truthy
        end
      end
    end
  end

  describe '#total_on_hand' do
    it 'matches quantifier total_on_hand' do
      variant = build(:variant)
      expect(variant.total_on_hand).to eq(Spree::Stock::Quantifier.new(variant).total_on_hand)
    end
  end

  describe "scopes" do
    # TODO rename describer below with scope names
    describe "finding variants in a distributor" do
      let!(:d1) { create(:distributor_enterprise) }
      let!(:d2) { create(:distributor_enterprise) }
      let!(:p1) { create(:simple_product) }
      let!(:p2) { create(:simple_product) }
      let!(:oc1) { create(:simple_order_cycle, distributors: [d1], variants: [p1.variants.first]) }
      let!(:oc2) { create(:simple_order_cycle, distributors: [d2], variants: [p2.variants.first]) }

      it "shows variants in an order cycle distribution" do
        expect(Spree::Variant.in_distributor(d1)).to eq([p1.variants.first])
      end

      it "doesn't show duplicates" do
        oc_dup = create(:simple_order_cycle, distributors: [d1], variants: [p1.variants.first])
        expect(Spree::Variant.in_distributor(d1)).to eq([p1.variants.first])
      end
    end

    describe "finding variants in an order cycle" do
      let!(:d1) { create(:distributor_enterprise) }
      let!(:d2) { create(:distributor_enterprise) }
      let!(:p1) { create(:product) }
      let!(:p2) { create(:product) }
      let!(:oc1) { create(:simple_order_cycle, distributors: [d1], variants: [p1.variants.first]) }
      let!(:oc2) { create(:simple_order_cycle, distributors: [d2], variants: [p2.variants.first]) }

      it "shows variants in an order cycle" do
        expect(Spree::Variant.in_order_cycle(oc1)).to eq([p1.variants.first])
      end

      it "doesn't show duplicates" do
        ex = create(:exchange, order_cycle: oc1, sender: oc1.coordinator, receiver: d2)
        ex.variants << p1.variants.first

        expect(Spree::Variant.in_order_cycle(oc1)).to eq([p1.variants.first])
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

      let!(:hidden_inventory_item) {
        create(:inventory_item, enterprise:, variant: hidden_variant, visible: false )
      }
      let!(:visible_inventory_item) {
        create(:inventory_item, enterprise:, variant: visible_variant, visible: true )
      }

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
            expect(variants).not_to include hidden_variant
          end

          context "when inventory items exist for other enterprises" do
            let(:other_enterprise) { create(:distributor_enterprise) }

            let!(:new_inventory_item) {
              create(:inventory_item, enterprise: other_enterprise, variant: new_variant,
                                      visible: true )
            }
            let!(:hidden_inventory_item2) {
              create(:inventory_item, enterprise: other_enterprise, variant: visible_variant,
                                      visible: false )
            }
            let!(:visible_inventory_item2) {
              create(:inventory_item, enterprise: other_enterprise, variant: hidden_variant,
                                      visible: true )
            }

            it "lists any variants not listed as visible=false only for the relevant enterprise" do
              expect(variants).to include new_variant, visible_variant
              expect(variants).not_to include hidden_variant
            end
          end
        end
      end

      context "finding variants that are visible in an enterprise's inventory" do
        let!(:variants) { Spree::Variant.visible_for(enterprise) }

        it "lists any variants that are listed as visible=true" do
          expect(variants).to include visible_variant
          expect(variants).not_to include new_variant, hidden_variant
        end
      end
    end

    describe ".with_properties" do
      let!(:variant_without_wanted_property_on_supplier) {
        create(:variant, supplier: supplier_without_wanted_property)
      }
      let!(:variant_with_wanted_property_on_supplier) {
        create(:variant, supplier: supplier_with_wanted_property)
      }
      let(:supplier_with_wanted_property) {
        create(:supplier_enterprise, properties: [wanted_property])
      }
      let(:supplier_without_wanted_property) {
        create(:supplier_enterprise, properties: [unwanted_property])
      }
      let(:wanted_property) { create(:property, presentation: 'Certified Organic') }
      let(:unwanted_property) { create(:property, presentation: 'Latest Hype') }

      it "returns no products without a property id" do
        expect(Spree::Variant.with_properties([])).to eq []
      end

      it "returns only variants with the wanted property set on supplier" do
        expect(
          Spree::Variant.with_properties([wanted_property.id])
        ).to match_array [variant_with_wanted_property_on_supplier]
      end
    end
  end

  describe "indexing variants by id" do
    let!(:v1) { create(:variant) }
    let!(:v2) { create(:variant) }
    let!(:v3) { create(:variant) }

    it "indexes variants by id" do
      expect(Spree::Variant.where(id: [v1, v2, v3]).indexed).to eq(
        v1.id => v1, v2.id => v2, v3.id => v3
      )
    end
  end

  describe ".linked_to" do
    let!(:variant_unlinked) { create(:variant) }
    let!(:variant_linked) { create(:variant, semantic_links: [link]) }
    let!(:variant_linked_unrelated) { create(:variant, semantic_links: [unrelated_link]) }
    let(:link) { SemanticLink.new(semantic_id: "#my_precious") }
    let(:unrelated_link) { SemanticLink.new(semantic_id: "#other") }

    it "finds a variant by link" do
      expect(Spree::Variant.linked_to("#my_precious"))
        .to eq variant_linked
    end
  end

  describe "generating the product and variant name" do
    let(:product) { variant.product }

    context "when full_name starts with the product name" do
      before do
        product.name = "Apple"
        variant.display_as = "Apple Pink Lady"
      end

      it "does not show the product name twice" do
        expect(variant.product_and_full_name).to eq "Apple Pink Lady"
      end
    end

    context "when full_name does not start with the product name" do
      before do
        product.name = "Apple"
        variant.display_as = "Pink Lady"
      end

      it "prepends the product name to the full name" do
        expect(variant.product_and_full_name).to eq "Apple - Pink Lady"
      end
    end

    context "handling nil values for related naming attributes" do
      it "returns empty string or product name" do
        product.name = "Apple"
        product.display_as = nil
        variant.variant_unit = "items"
        variant.display_as = nil
        variant.display_name = nil

        expect(variant.full_name).to eq ""
        expect(variant.product_and_full_name).to eq product.name
      end

      it "uses the display name correctly" do
        product.name = "Apple"
        product.display_as = nil
        variant.variant_unit = "items"
        variant.display_as = nil
        variant.unit_presentation = nil
        variant.display_name = "Green"

        expect(variant.full_name).to eq "Green"
        expect(variant.product_and_full_name).to eq "Apple - Green"
      end
    end
  end

  describe "calculating the price with enterprise fees" do
    it "returns the price plus the fees" do
      distributor = instance_double(Enterprise)
      order_cycle = instance_double(OrderCycle)

      variant = Spree::Variant.new price: 100
      expect(variant).to receive(:fees_for).with(distributor, order_cycle) { 23 }
      expect(variant.price_with_fees(distributor, order_cycle)).to eq(123)
    end
  end

  describe "calculating the fees" do
    it "delegates to EnterpriseFeeCalculator" do
      distributor = instance_double(Enterprise)
      order_cycle = instance_double(OrderCycle)
      variant = Spree::Variant.new

      expect_any_instance_of(OpenFoodNetwork::EnterpriseFeeCalculator)
        .to receive(:fees_for).with(variant) { 23 }

      expect(variant.fees_for(distributor, order_cycle)).to eq(23)
    end
  end

  describe "calculating fees broken down by fee type" do
    it "delegates to EnterpriseFeeCalculator" do
      distributor = instance_double(Enterprise)
      order_cycle = instance_double(OrderCycle)
      variant = Spree::Variant.new
      fees = instance_double(EnterpriseFee)

      expect_any_instance_of(OpenFoodNetwork::EnterpriseFeeCalculator)
        .to receive(:fees_by_type_for).with(variant) { fees }

      expect(variant.fees_by_type_for(distributor, order_cycle)).to eq(fees)
    end
  end

  describe "unit value/description" do
    let(:v) { Spree::Variant.new(unit_presentation: "small" ) }

    describe "generating the full name" do
      it "returns unit_to_display when display_name is blank" do
        v.display_name = ""
        expect(v.full_name).to eq("small")
      end

      it "returns display_name when it contains unit_to_display" do
        v.display_name = "a small apple"
        expect(v.full_name).to eq "a small apple"
      end

      it "returns unit_to_display when it contains display_name" do
        v.display_name = "small"
        v.unit_presentation = "small size"
        expect(v.full_name).to eq "small size"
      end

      it "returns a combination otherwise" do
        v.display_name = "apple"
        expect(v.full_name).to eq "apple (small)"
      end

      it "is resilient to regex chars" do
        v.display_name = ")))"
        v.unit_presentation = ")))"
        expect(v.full_name).to eq(")))")
      end
    end

    describe "getting name for display" do
      it "returns display_name if present" do
        v.display_name = "foo"
        expect(v.name_to_display).to eq("foo")
      end

      it "returns product name if display_name is empty" do
        v.product = Spree::Product.new(name: "Apple")
        v.display_name = nil
        expect(v.name_to_display).to eq "Apple"

        v.display_name = ""
        expect(v.name_to_display).to eq "Apple"
      end
    end

    describe "getting unit for display" do
      it "returns display_as if present" do
        v.display_as = "foo"
        expect(v.unit_to_display).to eq("foo")
      end

      it "returns options_text if display_as is blank" do
        v.display_as = nil
        expect(v.unit_to_display).to eq("small")

        v.display_as = ""
        expect(v.unit_to_display).to eq("small")
      end
    end

    describe "setting the variant's weight from the unit value" do
      it "sets the variant's weight when unit is weight" do
        v = create(:variant, weight: 0)
        v.update!(
          variant_unit: 'weight', variant_unit_scale: 1, unit_value: 10, unit_description: 'foo'
        )

        expect(v.reload.weight).to eq(0.01)
      end

      it "does nothing when unit is not weight" do
        v = create(:variant, weight: 123, variant_unit: 'volume')
        v.update! variant_unit: 'volume', variant_unit_scale: 1, unit_value: 10,
                  unit_description: 'foo'

        expect(v.reload.weight).to eq(123)
      end

      it "does nothing when unit_value is not set" do
        v = create(:variant, weight: 123, variant_unit: 'volume')

        # Although invalid, this calls the before_validation callback, which would
        # error if not handling unit_value == nil case
        expect(
          v.update(variant_unit: "weight", variant_unit_scale: 1, unit_value: nil,
                   unit_description: "foo")
        ).to be false

        expect(v.reload.weight).to eq(123)
      end
    end

    context "when the variant already has a value set" do
      let!(:v) {
        create(:variant, variant_unit: 'weight', variant_unit_scale: 1, unit_value: 5,
                         unit_description: 'bar')
      }

      it "assigns the new option value" do
        expect(v.unit_presentation).to eq "5g bar"

        v.update!(unit_value: 10, unit_description: 'foo')

        expect(v.unit_presentation).to eq "10g foo"
      end
    end

    context "when the variant does not have a display_as value set" do
      let!(:v) {
        create(:variant, variant_unit: 'weight', variant_unit_scale: 1, unit_value: 5,
                         unit_description: 'bar', display_as: '')
      }

      it "requests the new value from OptionValueName" do
        expect_any_instance_of(VariantUnits::OptionValueNamer)
          .to receive(:name).exactly(1).times.and_call_original
        v.update(unit_value: 10, unit_description: 'foo')

        expect(v.unit_presentation).to eq "10g foo"
      end
    end

    context "when the variant has a display_as value set" do
      let!(:v) {
        create(:variant, variant_unit: 'weight', variant_unit_scale: 1, unit_value: 5,
                         unit_description: 'bar', display_as: 'FOOS!')
      }

      it "does not request the new value from OptionValueName" do
        expect_any_instance_of(VariantUnits::OptionValueNamer).not_to receive(:name)
        v.update!(unit_value: 10, unit_description: 'foo')

        expect(v.unit_presentation).to eq("FOOS!")
      end
    end
  end

  context "extends LocalizedNumber" do
    subject! { build_stubbed(:variant) }

    it_behaves_like "a model using the LocalizedNumber module", [:price, :weight]
  end

  context "in a circular order cycle setup" do
    let(:enterprise1) { create(:distributor_enterprise, is_primary_producer: true) }
    let(:enterprise2) { create(:distributor_enterprise, is_primary_producer: true) }
    let(:variant1) { create(:variant) }
    let(:variant2) { create(:variant) }
    let!(:order_cycle) do
      enterprise1.supplied_variants << variant1
      enterprise2.supplied_variants << variant2
      create(
        :simple_order_cycle,
        coordinator: enterprise1,
        suppliers: [enterprise1, enterprise2],
        distributors: [enterprise1, enterprise2],
        variants: [variant1, variant2]
      )
    end

    it "saves without infinite loop" do
      expect(variant1.update(price: 1)).to be_truthy
    end
  end

  describe "destruction" do
    it "destroys exchange variants" do
      variant = create(:variant)
      exchange = create(:exchange, variants: [variant])

      variant.destroy
      expect(exchange.reload.variant_ids).to be_empty
    end

    it "touches the supplier" do
      supplier = create(:supplier_enterprise, updated_at: 1.hour.ago)
      variant = create(:variant, supplier:)

      expect { variant.destroy }.to change { supplier.reload.updated_at }
    end

    it "touches distributors" do
      variant = create(:variant)
      updated_at = 1.hour.ago
      distributor1 = create(:distributor_enterprise, updated_at:)
      distributor2 = create(:distributor_enterprise, updated_at:)

      create(:simple_order_cycle, distributors: [distributor1], variants: [variant])
      create(:simple_order_cycle, distributors: [distributor2], variants: [variant])

      expect { variant.destroy }
        .to change { distributor1.reload.updated_at }
        .and change { distributor2.reload.updated_at }
    end
  end

  describe "#ensure_unit_value" do
    let(:variant) { create(:variant, variant_unit: "weight") }

    context "when  variant_unit value is changed from weight to items" do
      it "sets the variant's unit_value to 1" do
        variant.update(variant_unit: "items")

        expect(variant.unit_value).to eq 1
      end
    end

    context "trying to set an invalid unit_value" do
      it "does not allow NaN" do
        variant.update(unit_value: Float::NAN)

        expect(variant.reload.unit_value).to eq(1.0)
      end
    end
  end

  describe "#default_price" do
    let(:variant) { create(:variant) }
    let(:default_price) { variant.default_price }

    context "when the default price is soft-deleted" do
      it "can access the default price" do
        price_id = default_price.id

        default_price.destroy

        expect(variant.reload.default_price).to be_a Spree::Price
        expect(variant.default_price.id).to eq price_id
      end
    end
  end

  describe "after save callback" do
    let(:variant) { create(:variant) }

    it "updates units and unit_presenation when saved change to variant unit" do
      variant.variant_unit = 'items'
      variant.variant_unit_scale = nil
      variant.variant_unit_name = 'loaf'
      variant.save!

      expect(variant.variant_unit_name).to eq 'loaf'
      expect(variant.unit_presentation).to eq "1 loaf"

      variant.update(variant_unit_name: 'bag')

      expect(variant.variant_unit_name).to eq 'bag'
      expect(variant.unit_presentation).to eq "1 bag"

      variant.variant_unit = 'weight'
      variant.variant_unit_scale = 1
      variant.save!

      expect(variant.variant_unit).to eq 'weight'
      expect(variant.unit_presentation).to eq "1g"
      expect(variant.variant_unit_name).to eq('')

      variant.update(variant_unit: 'volume')

      expect(variant.variant_unit).to eq 'volume'
      expect(variant.unit_presentation).to eq "1L"

      variant.update(display_as: 'My display')

      expect(variant.unit_presentation).to eq "My display"
    end
  end
end
