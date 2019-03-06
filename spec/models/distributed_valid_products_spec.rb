require 'spec_helper'

describe DistributedValidProducts do
  it "returns valid products but not invalid products" do
    p_valid = create(:product)
    p_invalid = create(:product)
    v_valid = p_valid.variants.first
    v_invalid = p_invalid.variants.first

    d = create(:distributor_enterprise)
    oc = create(:simple_order_cycle, distributors: [d], variants: [v_valid, p_invalid.master])

    expect(oc.valid_products_distributed_by(d)).to eq([p_valid])
  end

  describe "checking if a product has only an obsolete master variant in a distributution" do
    it "returns true when so" do
      master = double(:master)
      unassociated_variant = double(:variant)
      product = double(:product, has_variants?: true, master: master, variants: [])
      distributed_variants = [master, unassociated_variant]

      oc = OrderCycle.new
      distributed_valid_products = described_class.new(oc, nil)

      expect(distributed_valid_products.send(:product_has_only_obsolete_master_in_distribution?, product, distributed_variants)).to be true
    end

    it "returns false when the product doesn't have variants" do
      master = double(:master)
      product = double(:product, has_variants?: false, master: master, variants: [])
      distributed_variants = [master]

      oc = OrderCycle.new
      distributed_valid_products = described_class.new(oc, nil)

      expect(distributed_valid_products.send(:product_has_only_obsolete_master_in_distribution?, product, distributed_variants)).to be false
    end

    it "returns false when the master isn't distributed" do
      master = double(:master)
      product = double(:product, has_variants?: true, master: master, variants: [])
      distributed_variants = []

      oc = OrderCycle.new
      distributed_valid_products = described_class.new(oc, nil)

      expect(distributed_valid_products.send(:product_has_only_obsolete_master_in_distribution?, product, distributed_variants)).to be false
    end

    it "returns false when the product has other variants distributed" do
      master = double(:master)
      variant = double(:variant)
      product = double(:product, has_variants?: true, master: master, variants: [variant])
      distributed_variants = [master, variant]

      oc = OrderCycle.new
      distributed_valid_products = described_class.new(oc, nil)

      expect(distributed_valid_products.send(:product_has_only_obsolete_master_in_distribution?, product, distributed_variants)).to be false
    end
  end
end
