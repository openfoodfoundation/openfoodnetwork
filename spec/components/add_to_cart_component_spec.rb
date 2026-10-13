# frozen_string_literal: true

RSpec.describe AddToCartComponent, type: :component do
  subject(:render_component) do
    render_inline(described_class.new(variant:, cart_item:, low_stock_display: 0))
  end

  let(:producer) { build_stubbed(:enterprise, name: "Fred's Farm") }
  let(:cart_item) { ViewData::CartItem.empty }
  let(:variant) { build_variant }

  def build_variant(group_buy: false, **overrides)
    ViewData::Variant.new(
      id: 1, on_demand: false, on_hand: 10, display_name: "", name_to_display: "Beans",
      unit_to_display: "1kg", price: 10, price_with_fees: 12,
      display_price_with_fees: "$12.00", unit_price: UnitPrice.new(build_stubbed(:variant)),
      display_unit_price: "$12.00", fees: {}, fee_names: {}, enterprise: producer, producer:,
      product: ViewData::SimpleProduct.new(id: 1, name: "Beans", group_buy:)
    ).with(**overrides)
  end

  describe "for a regular (non group buy) variant" do
    it "renders a single stepper" do
      render_component

      expect(page).to have_selector "[data-add-to-cart-target='quantity']", count: 1,
                                                                            visible: :all
      expect(page).not_to have_selector "[data-add-to-cart-target='maxQuantity']", visible: :all
      expect(page).not_to have_selector ".variant-quantity-label", visible: :all
    end

    it "shows the quantity in cart and the remaining stock elements" do
      render_component

      expect(page).to have_selector "[data-add-to-cart-target='nbItemInCart']", visible: :all
      expect(page).to have_selector "[data-add-to-cart-target='stock']", visible: :all
    end

    it "does not flag the widget as group buy" do
      render_component

      expect(page).to have_selector "[data-add-to-cart-group-buy-value='false']"
    end
  end

  describe "for a group buy variant" do
    let(:variant) { build_variant(group_buy: true) }
    let(:cart_item) { ViewData::CartItem.new(quantity: 2, max_quantity: 5) }

    it "flags the widget as group buy" do
      render_component

      expect(page).to have_selector "[data-add-to-cart-group-buy-value='true']"
    end

    it "renders labelled min and max steppers" do
      render_component

      expect(page).to have_selector ".variant-quantity-label", text: "Min quantity",
                                                               visible: :all
      expect(page).to have_selector ".variant-quantity-label", text: "Max quantity",
                                                               visible: :all
      expect(page).to have_selector "[data-add-to-cart-target='quantity']", count: 1,
                                                                            visible: :all
      expect(page).to have_selector "[data-add-to-cart-target='maxQuantity']", count: 1,
                                                                               visible: :all
    end

    it "seeds the min and max inputs from the cart item" do
      render_component

      expect(page.find("[data-add-to-cart-target='quantity']", visible: :all).value).to eq "2"
      expect(page.find("[data-add-to-cart-target='maxQuantity']", visible: :all).value).to eq "5"
    end

    it "does not show the quantity in cart or remaining stock elements" do
      render_component

      expect(page).not_to have_selector "[data-add-to-cart-target='nbItemInCart']", visible: :all
      expect(page).not_to have_selector "[data-add-to-cart-target='stock']", visible: :all
    end
  end

  # Capybara matches aria labels only in system specs, see capybara_setup.rb.
  describe "labels" do
    let(:variant) { build_variant(display_name: "Big bag", unit_to_display: "2kg") }
    let(:name) { "Beans - Big bag - 2kg" }

    it "names the variant on its buttons and its quantity field" do
      render_component

      expect(page).to have_selector "button[aria-label='Add #{name} to cart']"

      # The quantity controls show once there's some in the cart.
      expect(page).to have_selector "button[aria-label='Decrease quantity of #{name}']",
                                    visible: :all
      expect(page).to have_selector "button[aria-label='Increase quantity of #{name}']",
                                    visible: :all
      expect(page).to have_selector "input[aria-label='Quantity of #{name}']", visible: :all
    end

    context "when the variant has no name of its own" do
      let(:variant) { build_variant(display_name: "", unit_to_display: "2kg") }

      it "names the product and the unit" do
        render_component

        expect(page).to have_selector "button[aria-label='Add Beans - 2kg to cart']"
      end
    end

    context "for a group buy variant" do
      let(:variant) {
        build_variant(group_buy: true, display_name: "Big bag", unit_to_display: "2kg")
      }

      it "tells the maximum quantity controls apart" do
        render_component

        expect(page).to have_selector(
          "button[aria-label='Decrease maximum quantity of #{name}']", visible: :all
        )
        expect(page).to have_selector(
          "button[aria-label='Increase maximum quantity of #{name}']", visible: :all
        )
        expect(page).to have_selector "input[aria-label='Maximum quantity of #{name}']",
                                      visible: :all
      end
    end
  end
end
