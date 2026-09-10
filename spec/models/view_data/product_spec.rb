# frozen_string_literal: true

RSpec.describe ViewData::Product do
  let(:producer) { build_stubbed(:enterprise, name: "Fred's Farm") }

  def build_variant(**overrides)
    ViewData::Variant.new(
      id: 1, on_demand: false, on_hand: 5, display_name: "", name_to_display: "Beans",
      unit_to_display: "1kg", price: 10, price_with_fees: 12,
      display_price_with_fees: "$12.00", unit_price: nil, display_unit_price: "$12.00",
      enterprise: producer, producer:,
      product: ViewData::SimpleProduct.new(id: 1, name: "Beans")
    ).with(**overrides)
  end

  def build_product(variants)
    described_class.new(id: 1, name: "Beans", description: nil, image: nil, images: [],
                        variant_images: [], properties_including_inherited: [], variants:)
  end

  describe "#single_variant? and #variant" do
    it "identifies the only variant" do
      only = build_variant(id: 1)
      product = build_product([only])

      expect(product).to be_single_variant
      expect(product.variant).to eq only
    end

    it "has no single variant when there are several" do
      product = build_product([build_variant(id: 1), build_variant(id: 2)])

      expect(product).not_to be_single_variant
      expect(product.variant).to be_nil
    end

    it "has no single variant when there are none" do
      product = build_product([])

      expect(product).not_to be_single_variant
      expect(product.variant).to be_nil
    end
  end

  describe "#producers and #single_producer?" do
    it "is a single producer when every variant shares one" do
      product = build_product([build_variant(id: 1), build_variant(id: 2)])

      expect(product.producers).to eq [producer]
      expect(product).to be_single_producer
    end

    it "is not a single producer when one variant differs" do
      other = build_stubbed(:enterprise, name: "Another Farm")
      product = build_product([build_variant(id: 1), build_variant(id: 2, producer: other)])

      expect(product.producers).to contain_exactly(producer, other)
      expect(product).not_to be_single_producer
    end

    # A linked variant is owned by the reselling hub but produced by the source variant's
    # enterprise. Grouping on `enterprise` would wrongly report two producers here.
    it "is a single producer for linked variants resold by different enterprises" do
      hub = build_stubbed(:enterprise, name: "Reselling Hub")
      product = build_product([
                                build_variant(id: 1),
                                build_variant(id: 2, enterprise: hub, producer:)
                              ])

      expect(product).to be_single_producer
      expect(product.producers).to eq [producer]
    end
  end

  describe "#cheapest_variant" do
    # Fees vary per variant, so the cheapest listed price is not necessarily the cheapest
    # to actually buy.
    it "is the lowest price including fees, not the lowest listed price" do
      dearer_before_fees = build_variant(id: 1, price: 12, price_with_fees: 15)
      cheaper_before_fees = build_variant(id: 2, price: 10, price_with_fees: 20)
      product = build_product([cheaper_before_fees, dearer_before_fees])

      expect(product.cheapest_variant).to eq dearer_before_fees
    end

    it "is nil without variants" do
      expect(build_product([]).cheapest_variant).to be_nil
    end
  end
end
