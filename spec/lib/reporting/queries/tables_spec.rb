# frozen_string_literal: true

RSpec.describe Reporting::Queries::Tables do
  subject(:tables) { Class.new { include Reporting::Queries::Tables }.new }

  describe "#producer_name_field" do
    let(:variant) { create(:variant) }

    def producer_name_for(variant)
      Spree::Variant.where(id: variant.id).pick(tables.producer_name_field)
    end

    it "returns nil when the variant has no linked source variant" do
      expect(producer_name_for(variant)).to be_nil
    end

    context "with a linked source variant" do
      let(:source_enterprise) { create(:enterprise) }
      let!(:source_variant) do
        create(:variant, target_variants: [variant], enterprise: source_enterprise)
      end

      it "returns the name of the source variant's enterprise" do
        expect(producer_name_for(variant)).to eq source_enterprise.name
      end
    end

    context "with multiple linked source variants" do
      let(:source_enterprise) { create(:enterprise) }
      let!(:first_source_variant) do
        create(:variant, target_variants: [variant], enterprise: source_enterprise)
      end
      let!(:second_source_variant) { create(:variant, target_variants: [variant]) }

      it "returns the name of the first linked source variant's enterprise" do
        expect(producer_name_for(variant)).to eq source_enterprise.name
      end
    end
  end
end
