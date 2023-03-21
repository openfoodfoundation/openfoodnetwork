# frozen_string_literal: true

require DfcProvider::Engine.root.join("spec/spec_helper")

describe VariantFetcher do
  subject { VariantFetcher.new(enterprise) }
  let(:enterprise) { build(:enterprise) }
  let(:other_enterprise) { build(:enterprise) }

  it "returns an empty set" do
    expect(subject.scope).to eq []
  end

  it "returns the variants of a supplier" do
    product = create(:product, supplier: enterprise)

    expect(subject.scope.count).to eq 1
    expect(subject.scope).to eq product.variants
  end

  it "ignores the variants of another enterprise" do
    create(:product, supplier: other_enterprise)

    expect(subject.scope).to eq []
  end
end
