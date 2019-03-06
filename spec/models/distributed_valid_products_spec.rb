require 'spec_helper'

describe DistributedValidProducts do
  let(:order_cycle) { OrderCycle.new }
  let(:distributor) { instance_double(Enterprise) }

  it 'returns valid products but not invalid products' do
    valid_product = create(:product)
    invalid_product = create(:product)
    valid_variant = valid_product.variants.first

    distributor = create(:distributor_enterprise)
    order_cycle = create(
      :simple_order_cycle,
      distributors: [distributor],
      variants: [valid_variant, invalid_product.master]
    )

    distributed_valid_products = described_class.new(order_cycle, distributor)

    expect(distributed_valid_products.relation).to eq([valid_product])
  end

  context 'when the product has only an obsolete master variant in a distribution' do
    let(:master) { create(:variant, product: product) }
    let(:product) { create(:product, variants: [build(:variant)]) }
    let(:unassociated_variant) { create(:variant) }
    let(:distributed_variants) { [product.master, unassociated_variant] }

    before do
      allow(order_cycle)
        .to receive(:variants_distributed_by).with(distributor) { distributed_variants }
    end

    it 'does not return the obsolete product' do
      distributed_valid_products = described_class.new(order_cycle, distributor)
      expect(distributed_valid_products.relation).to eq([unassociated_variant.product])
    end
  end

  context "when the product doesn't have variants" do
    let(:master) { build(:variant) }
    let(:product) { create(:product, master: master) }
    let(:distributed_variants) { [master] }

    before do
      allow(product).to receive(:has_variants?) { false }
      allow(order_cycle)
        .to receive(:variants_distributed_by).with(distributor) { distributed_variants }
    end

    it 'returns the product' do
      distributed_valid_products = described_class.new(order_cycle, distributor)
      expect(distributed_valid_products.relation).to eq([product])
    end
  end

  context "when the master isn't distributed" do
    let(:master) { build(:variant) }
    let(:variant) { build(:variant) }
    let(:product) { create(:product, master: master, variants: [variant]) }
    let(:distributed_variants) { [variant] }

    before do
      allow(product).to receive(:has_variants?) { true }
      allow(order_cycle)
        .to receive(:variants_distributed_by).with(distributor) { distributed_variants }
    end

    it 'returns the product' do
      distributed_valid_products = described_class.new(order_cycle, distributor)
      expect(distributed_valid_products.relation).to eq([product])
    end
  end

  context 'when the product has the master and other variants distributed' do
    let(:master) { build(:variant) }
    let(:variant) { build(:variant) }
    let(:product) { create(:product, master: master, variants: [variant]) }
    let(:distributed_variants) { [master, variant] }

    before do
      allow(product).to receive(:has_variants?) { true }
      allow(order_cycle)
        .to receive(:variants_distributed_by).with(distributor) { distributed_variants }
    end

    it 'returns the product' do
      distributed_valid_products = described_class.new(order_cycle, distributor)
      expect(distributed_valid_products.relation).to eq([product])
    end
  end
end
