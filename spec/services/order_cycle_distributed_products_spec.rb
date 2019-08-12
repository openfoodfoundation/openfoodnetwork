require 'spec_helper'

describe OrderCycleDistributedProducts do
  let(:order_cycle) { build(:order_cycle) }
  let(:distributor) { create(:enterprise) }
  let(:exchange) do
    create(
      :exchange,
      order_cycle: order_cycle,
      incoming: false,
      receiver: distributor,
      sender: product.supplier
    )
  end

  it 'returns valid products but not invalid products' do
    valid_product = create(:product)
    invalid_product = create(:product)
    valid_variant = valid_product.variants.first

    distributor = create(:distributor_enterprise)
    order_cycle = create(
      :simple_order_cycle,
      suppliers: [valid_product.supplier],
      distributors: [distributor],
      variants: [valid_variant, invalid_product.master]
    )

    distributed_valid_products = described_class.new(order_cycle, distributor)
    expect(distributed_valid_products.relation.map(&:id)).to eq([valid_product.id])
  end

  context 'when the product has only an obsolete master variant in a distribution' do
    let(:master) { create(:variant, product: product) }
    let(:product) { create(:product, variants: [build(:variant)]) }
    let(:unassociated_variant) { create(:variant) }
    let(:distributed_variants) { [product.master, unassociated_variant] }

    before do
      product.master.exchanges << exchange
      unassociated_variant.exchanges << exchange
    end

    it 'does not return the obsolete product' do
      distributed_valid_products = described_class.new(order_cycle, distributor)
      expect(distributed_valid_products.relation).to eq([unassociated_variant.product])
    end
  end

  context "when the product doesn't have variants" do
    let(:product) { create(:product) }

    before do
      product.variants.destroy_all
      product.master.exchanges << exchange
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

    before { variant.exchanges << exchange }

    it 'returns the product' do
      distributed_valid_products = described_class.new(order_cycle, distributor)
      expect(distributed_valid_products.relation).to eq([product])
    end
  end

  context 'when the product has the master and other variants distributed' do
    let(:master) { build(:variant) }
    let(:variant) { build(:variant) }
    let(:product) { create(:product, master: master, variants: [variant]) }

    before do
      master.exchanges << exchange
      variant.exchanges << exchange
    end

    it 'returns the product' do
      distributed_valid_products = described_class.new(order_cycle, distributor)
      expect(distributed_valid_products.relation).to eq([product])
    end
  end

  def output(name, result)
    puts "\n#{name}"
    result.each { |r| puts r }
  end

  def with_execution_tags(method)
    Rails.logger.debug "\n==== BEGIN #{method}"
    yield
    Rails.logger.debug "==== END #{method}\n"
  end
end
