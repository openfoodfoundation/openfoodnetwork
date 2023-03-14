# frozen_string_literal: true

require DfcProvider::Engine.root.join("spec/spec_helper")

describe DfcBuilder do
  let(:variant) {
    build(:variant, id: 5).tap { |v| v.product.supplier_id = 7 }
  }

  describe ".supplied_product" do
    it "assigns a semantic id" do
      product = DfcBuilder.supplied_product(variant)

      expect(product.semanticId).to eq(
        "http://test.host/api/dfc-v1.6/enterprises/7/supplied_products/5"
      )
    end

    it "assigns a quantity" do
      product = DfcBuilder.supplied_product(variant)

      expect(product.quantity.value).to eq 1.0
      expect(product.quantity.unit.semanticId).to eq "dfc-m:Gram"
    end
  end
end
