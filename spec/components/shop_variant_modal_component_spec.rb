# frozen_string_literal: true

RSpec.describe ShopVariantModalComponent, type: :component do
  subject(:render_modal) do
    render_inline(described_class.new(product:, variants_in_cart: {}, low_stock_display: 0))
  end

  let(:producer) { build_stubbed(:enterprise, name: "Fred's Farm") }

  def build_variant(**overrides)
    ViewData::Variant.new(
      id: 1, on_demand: true, on_hand: 0, display_name: "Borlotti", name_to_display: "Borlotti",
      unit_to_display: "1kg", price: 10, price_with_fees: 12,
      display_price_with_fees: "$12.00", unit_price: UnitPrice.new(build_stubbed(:variant)),
      display_unit_price: "$12.00", enterprise: producer, producer:,
      product: ViewData::SimpleProduct.new(id: 1, name: "Beans")
    ).with(**overrides)
  end

  def build_product(variants)
    ViewData::Product.new(id: 1, name: "Beans", description: nil, image: nil, images: [],
                          variant_images: [], properties_including_inherited: [], variants:)
  end

  context "when the variants come from one producer" do
    let(:product) { build_product([build_variant(id: 1), build_variant(id: 2)]) }

    it "names the producer once, in the header" do
      render_modal

      expect(page).to have_selector ".producer", text: "From Fred's Farm"
      expect(page).not_to have_selector ".variant-producer"
    end
  end

  # A linked variant is owned by the reselling hub but produced by the source variant's
  # enterprise. Grouping on the variant's own enterprise would name the hub as a second
  # producer and repeat "Fred's Farm" on every row.
  context "when variants are linked and resold by different enterprises" do
    let(:hub) { build_stubbed(:enterprise, name: "Reselling Hub") }
    let(:product) {
      build_product([build_variant(id: 1), build_variant(id: 2, enterprise: hub, producer:)])
    }

    it "still names the single producer once" do
      render_modal

      expect(page).to have_selector ".producer", text: "From Fred's Farm"
      expect(page).not_to have_selector ".variant-producer"
      expect(page).not_to have_content "Reselling Hub"
    end
  end

  context "when the variants come from different producers" do
    let(:other) { build_stubbed(:enterprise, name: "Another Farm") }
    let(:product) {
      build_product([build_variant(id: 1), build_variant(id: 2, producer: other)])
    }

    it "names each producer on its own row instead of in the header" do
      render_modal

      expect(page).not_to have_selector ".header .producer"
      expect(page).to have_selector ".variant-producer", text: "From Fred's Farm"
      expect(page).to have_selector ".variant-producer", text: "From Another Farm"
    end
  end
end
