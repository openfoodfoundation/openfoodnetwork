# frozen_string_literal: true

RSpec.describe VariantUnits::OptionValueNamer do
  describe "generating option value name" do
    subject { described_class.new(v) }
    let(:v) { Spree::Variant.new }

    it "when description is blank" do
      allow(v).to receive(:unit_description) { nil }
      allow(subject).to receive(:value_scaled?) { true }
      allow(subject).to receive(:option_value_value_unit) { %w(value unit) }
      expect(subject.name).to eq("valueunit")
    end

    it "when description is present" do
      allow(v).to receive(:unit_description) { 'desc' }
      allow(subject).to receive(:option_value_value_unit) { %w(value unit) }
      allow(subject).to receive(:value_scaled?) { true }
      expect(subject.name).to eq("valueunit desc")
    end

    it "when value is blank and description is present" do
      allow(v).to receive(:unit_description) { 'desc' }
      allow(subject).to receive(:option_value_value_unit) { [nil, nil] }
      allow(subject).to receive(:value_scaled?) { true }
      expect(subject.name).to eq("desc")
    end

    it "spaces value and unit when value is unscaled" do
      allow(v).to receive(:unit_description) { nil }
      allow(subject).to receive(:option_value_value_unit) { %w(value unit) }
      allow(subject).to receive(:value_scaled?) { false }
      expect(subject.name).to eq("value unit")
    end
  end

  describe "determining if a variant's value is scaled" do
    it "returns true when the product has a scale" do
      v = Spree::Variant.new variant_unit_scale: 1000
      subject = described_class.new v

      expect(subject.__send__(:value_scaled?)).to be true
    end

    it "returns false otherwise" do
      v = Spree::Variant.new
      subject = described_class.new v

      expect(subject.__send__(:value_scaled?)).to be false
    end
  end

  describe "generating option value's value and unit" do
    before do
      allow(Spree::Config).to receive(:available_units).and_return("g,lb,oz,kg,T,mL,L,kL")
    end

    it "generates simple values" do
      v = instance_double(Spree::Variant, variant_unit: 'weight', variant_unit_scale: 1.0,
                                          unit_value: 100)

      option_value_namer = described_class.new v
      expect(option_value_namer.__send__(:option_value_value_unit)).to eq [100, 'g']
    end

    it "generates values when unit value is non-integer" do
      v = instance_double(Spree::Variant, variant_unit: 'weight', variant_unit_scale: 1.0,
                                          unit_value: 123.45)

      option_value_namer = described_class.new v
      expect(option_value_namer.__send__(:option_value_value_unit)).to eq [123.45, 'g']
    end

    it "returns a value of 1 when unit value equals the scale" do
      v = instance_double(Spree::Variant, variant_unit: 'weight', variant_unit_scale: 1000.0,
                                          unit_value: 1000.0)

      option_value_namer = described_class.new v
      expect(option_value_namer.__send__(:option_value_value_unit)).to eq [1, 'kg']
    end

    it "returns only values that are in the same measurement systems" do
      v = instance_double(Spree::Variant, variant_unit: 'weight', variant_unit_scale: 1.0,
                                          unit_value: 500)

      # 500g would convert to > 1 pound, but we don't want the namer to use
      # pounds since it's in a different measurement system.
      option_value_namer = described_class.new v
      expect(option_value_namer.__send__(:option_value_value_unit)).to eq [500, 'g']
    end

    it "generates values for all weight scales" do
      [[1.0, 'g'], [28.35, 'oz'], [453.6, 'lb'], [1000.0, 'kg'],
       [1_000_000.0, 'T']].each do |scale, unit|
        v = instance_double(Spree::Variant, variant_unit: 'weight', variant_unit_scale: scale,
                                            unit_value: 10.0 * scale)

        option_value_namer = described_class.new v
        expect(option_value_namer.__send__(:option_value_value_unit)).to eq [10, unit]
      end
    end

    it "generates values for all volume scales" do
      [[0.001, 'mL'], [1.0, 'L'], [1000.0, 'kL']].each do |scale, unit|
        v = instance_double(Spree::Variant, variant_unit: 'volume', variant_unit_scale: scale,
                                            unit_value: 3 * scale)

        option_value_namer = described_class.new v
        expect(option_value_namer.__send__(:option_value_value_unit)).to eq [3, unit]
      end
    end

    it "chooses the correct scale when value is very small" do
      v = instance_double(Spree::Variant, variant_unit: 'volume', variant_unit_scale: 0.001,
                                          unit_value: 0.0001)

      option_value_namer = described_class.new v
      expect(option_value_namer.__send__(:option_value_value_unit)).to eq [0.1, 'mL']
    end

    it "generates values for item units" do
      %w(packet box).each do |unit|
        v = instance_double(Spree::Variant, variant_unit: 'items', variant_unit_scale: nil,
                                            variant_unit_name: unit, unit_value: 100)

        option_value_namer = described_class.new v
        expect(option_value_namer.__send__(:option_value_value_unit)).to eq [100, unit.pluralize]
      end
    end

    it "don't crash when variant_unit_name is nil" do
      v = instance_double(Spree::Variant, variant_unit: 'items', variant_unit_scale: nil,
                                          variant_unit_name: nil, unit_value: 100)

      option_value_namer = described_class.new v
      expect(option_value_namer.__send__(:option_value_value_unit)).to eq [100, nil]
    end

    it "generates singular values for item units when value is 1" do
      v = instance_double(Spree::Variant, variant_unit: 'items', variant_unit_scale: nil,
                                          variant_unit_name: 'packet', unit_value: 1)

      option_value_namer = described_class.new v
      expect(option_value_namer.__send__(:option_value_value_unit)).to eq [1, 'packet']
    end

    it "returns [nil, nil] when unit value is not set" do
      v = instance_double(Spree::Variant, variant_unit: 'items', variant_unit_scale: nil,
                                          variant_unit_name: 'foo', unit_value: nil)

      option_value_namer = described_class.new v
      expect(option_value_namer.__send__(:option_value_value_unit)).to eq [nil, nil]
    end

    it "truncates value to 2 decimals maximum" do
      oz_scale = 28.35
      v = instance_double(Spree::Variant, variant_unit: 'weight', variant_unit_scale: oz_scale,
                                          unit_value: (12.5 * oz_scale).round(2))

      # The unit_value is stored rounded to 2 decimals
      # allow(v).to receive(:unit_value) { (12.5 * oz_scale).round(2) }
      option_value_namer = described_class.new v
      expect(option_value_namer.__send__(:option_value_value_unit)).to eq [BigDecimal(12.5, 6),
                                                                           'oz']
    end
  end
end
