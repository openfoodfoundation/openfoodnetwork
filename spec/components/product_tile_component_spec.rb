# frozen_string_literal: true

RSpec.describe ProductTileComponent, type: :component do
  subject(:render_tile) do
    render_inline(described_class.new(product:, variants_in_cart: {}, low_stock_display: 0))
  end

  let(:producer) { build_stubbed(:enterprise, name: "Fred's Farm") }
  let(:product) { build_product([build_variant]) }

  def build_variant(**overrides)
    ViewData::Variant.new(
      id: 1, on_demand: true, on_hand: 0, display_name: "", name_to_display: "Beans",
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

  describe "producer" do
    it "names the producer when every variant shares one" do
      render_tile

      expect(page).to have_selector ".producer", text: "Fred's Farm"
    end

    it "says multiple producers when they differ" do
      other = build_stubbed(:enterprise, name: "Another Farm")
      product = build_product([build_variant(id: 1), build_variant(id: 2, producer: other)])
      render_inline(described_class.new(product:, variants_in_cart: {}, low_stock_display: 0))

      expect(page).to have_selector ".producer", text: "Multiple producers"
    end
  end

  # `unit_to_display` already returns the custom "display unit as" label when one is set and the
  # computed unit otherwise, so the rules only branch on whether the variant is named.
  describe "name and unit" do
    def tile_name_for(product)
      render_inline(described_class.new(product:, variants_in_cart: {}, low_stock_display: 0))
      page.find(".product-name").text
    end

    it "shows the product name and unit" do
      product = build_product([build_variant(display_name: "", unit_to_display: "1kg")])

      expect(tile_name_for(product)).to eq "Beans | 1kg"
    end

    it "shows the custom unit label in place of the unit" do
      product = build_product([build_variant(display_name: "", unit_to_display: "punnet")])

      expect(tile_name_for(product)).to eq "Beans | punnet"
    end

    it "shows the variant name and the custom unit label" do
      product = build_product([
                                build_variant(display_name: "Borlotti", unit_to_display: "punnet")
                              ])

      expect(tile_name_for(product)).to eq "Beans | Borlotti | punnet"
    end

    it "shows the variant name and the unit" do
      product = build_product([
                                build_variant(display_name: "Borlotti", unit_to_display: "1kg")
                              ])

      expect(tile_name_for(product)).to eq "Beans | Borlotti | 1kg"
    end

    it "offers multiple options when the product has several variants" do
      product = build_product([build_variant(id: 1), build_variant(id: 2)])

      expect(tile_name_for(product)).to eq "Beans | multiple options"
    end

    # A variant sold by the item can have no unit to show, which would otherwise leave the
    # name ending in a separator.
    it "leaves no dangling separator when there is no unit" do
      product = build_product([build_variant(display_name: "", unit_to_display: "")])

      expect(tile_name_for(product)).to eq "Beans"
    end
  end

  describe "price" do
    it "shows the price of the only variant" do
      render_tile

      expect(page).to have_selector ".price", text: "$12.00"
    end

    # Fees vary per variant, so the lowest listed price is not necessarily the lowest to buy.
    it "starts from the lowest price including fees" do
      product = build_product([
                                build_variant(id: 1, price: 10, price_with_fees: 20,
                                              display_price_with_fees: "$20.00"),
                                build_variant(id: 2, price: 12, price_with_fees: 15,
                                              display_price_with_fees: "$15.00")
                              ])
      render_inline(described_class.new(product:, variants_in_cart: {}, low_stock_display: 0))

      expect(page).to have_selector ".price", text: "from $15.00"
    end
  end

  describe "unit price" do
    # The spaces around the slash don't break, so the price keeps its unit on one line.
    it "is shown for a single variant, with its unit" do
      render_tile

      expect(page).to have_selector ".product-link .unit-price"
      expect(rendered_content).to include "$12.00&nbsp;/&nbsp;kg"
    end

    # Variants come in different sizes, so there is no single unit price for the product.
    # The variant modal still shows one per row, so only the tile itself is checked.
    it "is hidden when the product has several variants" do
      product = build_product([build_variant(id: 1), build_variant(id: 2)])
      render_inline(described_class.new(product:, variants_in_cart: {}, low_stock_display: 0))

      expect(page).not_to have_selector ".product-link .unit-price"
    end
  end

  describe "rendering" do
    it "renders nothing when no variant is available in this shop" do
      product = build_product([])
      render_inline(described_class.new(product:, variants_in_cart: {}, low_stock_display: 0))

      expect(page).not_to have_selector ".product-item"
    end

    # The add to cart control must stay outside the link, otherwise clicking it would also
    # open the product details.
    it "keeps the add to cart control outside the product link" do
      render_tile

      expect(page).to have_selector "a.product-link"
      expect(page).not_to have_selector "a.product-link .add-to-cart-component"
    end
  end
end
