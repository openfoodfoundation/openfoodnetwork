# frozen_string_literal: true

require_relative "../spec_helper"

describe EnterpriseBuilder do
  subject(:builder) { described_class }
  let(:enterprise) {
    build(
      :enterprise,
      id: 10_000, name: "Fabi's Farm",
      description: "The place where stuff grows", abn: "123 456 789 0",
      address: build(:address, id: 40_000, city: "Melbourne"),
    )
  }
  let(:variant) {
    create(:product, supplier: enterprise, name: "Apple").variants.first
  }

  describe ".enterprise" do
    let(:result) { builder.enterprise(enterprise) }

    it "assigns a semantic id" do
      expect(result.semanticId).to eq(
        "http://test.host/api/dfc/enterprises/10000"
      )
    end

    it "assigns a name" do
      expect(result.name).to eq "Fabi's Farm"
    end

    it "assigns a description" do
      expect(result.description).to eq "The place where stuff grows"
    end

    it "assigns a VAT Number (ABN in australia)" do
      expect(result.vatNumber).to eq "123 456 789 0"
    end

    it "assigns products" do
      expect(variant).to be_persisted

      expect(result.suppliedProducts.count).to eq 1
      expect(result.suppliedProducts[0].name).to eq "Apple - 1g"
    end

    it "assigns an address" do
      expect(result.localizations.count).to eq 1
      expect(result.localizations[0].city).to eq "Melbourne"
    end
  end
end
