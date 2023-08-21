# frozen_string_literal: true

require DfcProvider::Engine.root.join("spec/spec_helper")

describe EnterpriseBuilder do
  subject(:builder) { described_class }
  let(:enterprise) { variant.product.supplier }
  let(:variant) { create(:product, name: "Apple").variants.first }

  describe ".enterprise" do
    let(:result) { builder.enterprise(enterprise) }

    it "assigns a semantic id" do
      expect(result.semanticId).to eq(
        "http://test.host/api/dfc-v1.7/enterprises/#{enterprise.id}"
      )
    end

    it "assigns a name" do
      expect(result.name).to eq(enterprise.name)
    end

    it "assigns a description" do
      expect(result.description).to eq(enterprise.description)
    end

    it "assigns a VAT Number (ABN in australia)" do
      expect(result.vatNumber).to eq(enterprise.abn)
    end

    it "assignes products" do
      expect(result.suppliedProducts.count).to eq 1
      expect(result.suppliedProducts[0].name).to eq "Apple"
    end
  end
end
