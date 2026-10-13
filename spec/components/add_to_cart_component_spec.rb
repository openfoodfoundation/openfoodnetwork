# frozen_string_literal: true

RSpec.describe AddToCartComponent, type: :component do
  subject(:render_widget) {
    render_inline(described_class.new(variant:, quantity: 0, low_stock_display: false))
  }

  let(:product) { create(:product, name: "Garlic") }
  let(:variant) {
    create(:variant, product:, display_name: "Big bag", unit_value: 2000)
  }

  # Capybara matches aria labels only in system specs, see capybara_setup.rb.
  it "names the variant on its buttons and its quantity field" do
    render_widget
    name = "Garlic - Big bag - 2kg"

    expect(page).to have_selector "button[aria-label='Add #{name} to cart']"

    # The quantity controls show once there's some in the cart.
    expect(page).to have_selector "button[aria-label='Decrease quantity of #{name}']",
                                  visible: :all
    expect(page).to have_selector "button[aria-label='Increase quantity of #{name}']",
                                  visible: :all
    expect(page).to have_selector "input[aria-label='Quantity of #{name}']", visible: :all
  end

  context "when the variant has no name of its own" do
    let(:variant) { create(:variant, product:, display_name: "", unit_value: 2000) }

    it "names the product and the unit" do
      render_widget

      expect(page).to have_selector "button[aria-label='Add Garlic - 2kg to cart']"
    end
  end
end
