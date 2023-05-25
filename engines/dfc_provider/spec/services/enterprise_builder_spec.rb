# frozen_string_literal: true

require DfcProvider::Engine.root.join("spec/spec_helper")

describe EnterpriseBuilder do
  subject(:builder) { described_class }
  let(:enterprise) { variant.product.supplier }
  let(:variant) { create(:product, name: "Apple").variants.first }

  describe ".enterprise" do
    it "assigns a semantic id" do
      result = builder.enterprise(enterprise)

      expect(result.semanticId).to eq(
        "http://test.host/api/dfc-v1.7/enterprises/#{enterprise.id}"
      )
    end

    it "assignes products" do
      result = builder.enterprise(enterprise)

      expect(result.suppliedProducts.count).to eq 1
      expect(result.suppliedProducts[0].name).to eq "Apple"
    end
  end
end
