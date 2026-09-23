# frozen_string_literal: true

RSpec.describe ShopVariantListComponent, type: :component do
  subject(:render_list) do
    render_inline(described_class.new(product:, variants_in_cart:, low_stock_display: false))
  end

  let(:producer) { build_stubbed(:enterprise, name: "Fred's Farm") }
  let(:variants_in_cart) { {} }

  def build_variant(**overrides)
    ViewData::Variant.new(
      id: 1, on_demand: false, on_hand: 3, display_name: "Borlotti", name_to_display: "Borlotti",
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

    it "lists each variant with its price" do
      render_list

      expect(page).to have_selector "li", count: 2
      expect(page).to have_selector ".variant-name", text: "Borlotti"
      expect(page).to have_selector ".prices", text: "$12.00"
      expect(page).to have_selector ".unit-price"
    end

    # The caller names the producer once above the list instead.
    it "doesn't name the producer on every row" do
      render_list

      expect(page).not_to have_selector ".variant-producer"
    end
  end

  context "when the variants come from different producers" do
    let(:other) { build_stubbed(:enterprise, name: "Another Farm") }
    let(:product) {
      build_product([build_variant(id: 1), build_variant(id: 2, producer: other)])
    }

    it "names each producer on its own row" do
      render_list

      expect(page).to have_selector ".variant-producer", text: "From Fred's Farm"
      expect(page).to have_selector ".variant-producer", text: "From Another Farm"
    end
  end

  context "when a variant has no name of its own" do
    let(:product) { build_product([build_variant(display_name: nil)]) }

    it "shows the unit without the name separator" do
      render_list

      expect(page).not_to have_selector ".variant-name"
      expect(page).to have_selector ".variant-unit", text: "1kg"
      expect(page).not_to have_content "|"
    end
  end

  describe "the add to cart widget" do
    let(:product) { build_product([build_variant(id: 7)]) }
    let(:variants_in_cart) { { 7 => 2 } }

    it "starts with the quantity already in the cart" do
      render_list

      expect(page).to have_selector "#variant-7", text: "2 in cart"
    end
  end
end
