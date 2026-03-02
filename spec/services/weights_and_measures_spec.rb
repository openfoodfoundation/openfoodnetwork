# frozen_string_literal: true

RSpec.describe WeightsAndMeasures do
  subject { WeightsAndMeasures.new(variant) }
  let(:variant) { instance_double(Spree::Variant) }
  let(:available_units) {
    ["mg", "g", "kg", "T", "oz", "lb", "mL", "cL", "dL", "L", "kL", "gal"].join(",")
  }

  before do
    allow(Spree::Config).to receive(:available_units).and_return(available_units)
  end

  describe "#system" do
    context "weight" do
      before do
        allow(variant).to receive(:variant_unit) { "weight" }
      end

      it "when scale is for a metric unit" do
        allow(variant).to receive(:variant_unit_scale) { 1.0 }
        expect(subject.system).to eq("metric")
      end

      it "when scale is for an imperial unit" do
        allow(variant).to receive(:variant_unit_scale) { 28.35 }
        expect(subject.system).to eq("imperial")
      end

      it "when precise scale is for an imperial unit" do
        allow(variant).to receive(:variant_unit_scale) { 28.349523125 }
        expect(subject.system).to eq("imperial")
      end
    end

    context "volume" do
      it "when scale is for a metric unit" do
        allow(variant).to receive(:variant_unit) { "volume" }
        allow(variant).to receive(:variant_unit_scale) { 1.0 }
        expect(subject.system).to eq("metric")
      end
    end

    context "items" do
      it "when variant unit is items" do
        allow(variant).to receive(:variant_unit) { "items" }
        allow(variant).to receive(:variant_unit_scale) { nil }
        expect(subject.system).to eq("custom")
      end

      it "when variant unit is items, even if the scale is present" do
        allow(variant).to receive(:variant_unit) { "items" }
        allow(variant).to receive(:variant_unit_scale) { 1.0 }
        expect(subject.system).to eq("custom")
      end
    end

    # In the event of corrupt data, we don't want an exception
    context "corrupt data" do
      it "when unit is invalid, scale is valid" do
        allow(variant).to receive(:variant_unit) { "blah" }
        allow(variant).to receive(:variant_unit_scale) { 1.0 }
        expect(subject.system).to eq("custom")
      end

      it "when unit is invalid, scale is nil" do
        allow(variant).to receive(:variant_unit) { "blah" }
        allow(variant).to receive(:variant_unit_scale) { nil }
        expect(subject.system).to eq("custom")
      end

      it "when unit is nil, scale is valid" do
        allow(variant).to receive(:variant_unit) { nil }
        allow(variant).to receive(:variant_unit_scale) { 1.0 }
        expect(subject.system).to eq("custom")
      end

      it "when unit is nil, scale is nil" do
        allow(variant).to receive(:variant_unit) { nil }
        allow(variant).to receive(:variant_unit_scale) { nil }
        expect(subject.system).to eq("custom")
      end

      it "when unit is valid, but scale is nil" do
        allow(variant).to receive(:variant_unit) { "weight" }
        allow(variant).to receive(:variant_unit_scale) { nil }
        expect(subject.system).to eq("custom")
      end

      it "when unit is valid, but scale is 0" do
        allow(variant).to receive(:variant_unit) { "weight" }
        allow(variant).to receive(:variant_unit_scale) { 0.0 }
        expect(subject.system).to eq("custom")
      end
    end
  end

  describe "#variant_unit_options" do
    let(:available_units) { "mg,g,kg,T,mL,cL,dL,L,kL,lb,oz,gal" }
    subject { WeightsAndMeasures.variant_unit_options }

    before do
      allow(Spree::Config).to receive(:available_units).and_return(available_units)
    end

    it "returns options for each unit" do
      expected_array = [
        ["Weight (mg)", "weight_0.001"],
        ["Weight (g)", "weight_1"],
        ["Weight (oz)", "weight_28.35"],
        ["Weight (lb)", "weight_453.6"],
        ["Weight (kg)", "weight_1000"],
        ["Weight (T)", "weight_1000000"],
        ["Volume (mL)", "volume_0.001"],
        ["Volume (cL)", "volume_0.01"],
        ["Volume (dL)", "volume_0.1"],
        ["Volume (L)", "volume_1"],
        ["Volume (gal)", "volume_4.54609"],
        ["Volume (kL)", "volume_1000"],
        ["Items", "items"],
      ]
      expect(subject).to match_array expected_array # diff each element
      expect(subject).to eq expected_array # test ordering also
    end

    describe "filtering available units" do
      let(:available_units) { "g,kg,mL,L,lb,oz" }

      it "returns options for available units only" do
        expected_array = [
          ["Weight (g)", "weight_1"],
          ["Weight (oz)", "weight_28.35"],
          ["Weight (lb)", "weight_453.6"],
          ["Weight (kg)", "weight_1000"],
          ["Volume (mL)", "volume_0.001"],
          ["Volume (L)", "volume_1"],
          ["Items", "items"],
        ]
        expect(subject).to match_array expected_array # diff each element
        expect(subject).to eq expected_array # test ordering also
      end
    end
  end

  describe "#scales_for_unit_value" do
    context "weight" do
      before do
        allow(variant).to receive(:variant_unit) { "weight" }
      end

      context "metric" do
        it "for a unit value that should display in grams" do
          allow(variant).to receive(:variant_unit_scale) { 1.0 }
          allow(variant).to receive(:unit_value) { 500 }
          expect(subject.scale_for_unit_value).to eq([1.0, "g"])
        end

        it "for a unit value that should display in kg" do
          allow(variant).to receive(:variant_unit_scale) { 1.0 }
          allow(variant).to receive(:unit_value) { 1500 }
          expect(subject.scale_for_unit_value).to eq([1000.0, "kg"])
        end

        describe "should not display in kg if this unit is not selected" do
          let(:available_units) { ["mg", "g", "T"].join(",") }

          it "should display in g" do
            allow(variant).to receive(:variant_unit_scale) { 1.0 }
            allow(variant).to receive(:unit_value) { 1500 }
            expect(subject.scale_for_unit_value).to eq([1.0, "g"])
          end
        end
      end
    end

    context "volume" do
      it "for a unit value that should display in kL" do
        allow(variant).to receive(:variant_unit) { "volume" }
        allow(variant).to receive(:variant_unit_scale) { 1.0 }
        allow(variant).to receive(:unit_value) { 1500 }
        expect(subject.scale_for_unit_value).to eq([1000, "kL"])
      end

      it "for a unit value that should display in dL" do
        allow(variant).to receive(:variant_unit) { "volume" }
        allow(variant).to receive(:variant_unit_scale) { 1.0 }
        allow(variant).to receive(:unit_value) { 0.5 }
        expect(subject.scale_for_unit_value).to eq([0.1, "dL"])
      end

      context "should not display in dL/cL if those units are not selected" do
        let(:available_units){ ["mL", "L", "kL", "gal"].join(",") }
        it "for a unit value that should display in mL" do
          allow(variant).to receive(:variant_unit) { "volume" }
          allow(variant).to receive(:variant_unit_scale) { 1.0 }
          allow(variant).to receive(:unit_value) { 0.5 }
          expect(subject.scale_for_unit_value).to eq([0.001, "mL"])
        end
      end
    end

    context "items" do
      it "when scale is for items" do
        allow(variant).to receive(:variant_unit) { "items" }
        allow(variant).to receive(:variant_unit_scale) { nil }
        allow(variant).to receive(:unit_value) { 4 }
        expect(subject.scale_for_unit_value).to eq([nil, nil])
      end
    end
  end
end
