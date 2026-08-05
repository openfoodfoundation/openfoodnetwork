# frozen_string_literal: true

RSpec.describe AddToCartComponent, type: :component do
  let(:variant) { create(:variant, on_demand: false, on_hand: 5) }

  it "renders the Add button for a variant not in the cart" do
    render_inline(described_class.new(variant:, order: nil))

    expect(page).to have_selector "form[action='/cart/variants/#{variant.id}']"
    expect(page).to have_selector '[data-controller="add-to-cart"]'
    expect(page).to have_button "Add"
    expect(page).not_to have_field "quantity"
  end

  it "renders the quantity controls for a variant in the cart" do
    order = create(:order)
    create(:line_item, order:, variant:, quantity: 3)
    order.line_items.reload

    render_inline(described_class.new(variant:, order:))

    expect(page).to have_field "quantity", with: "3"
    expect(page).to have_button "＋"
    expect(page).to have_button "－"
    expect(page).to have_content "3 in cart"
    expect(page).not_to have_button "Add"
  end

  it "disables the Add button when the variant is out of stock" do
    variant.update!(on_hand: 0)

    render_inline(described_class.new(variant:, order: nil))

    expect(page).to have_button "Add", disabled: true
  end

  describe "group buy" do
    before { variant.product.update!(group_buy: true) }

    it "renders the Add button and the bulk buy modal" do
      render_inline(described_class.new(variant:, order: nil))

      expect(page).to have_button "Add"
      expect(page).to have_selector "#bulk-buy-modal-#{variant.id}"
      expect(page).to have_content "Min quantity"
      expect(page).to have_content "Max quantity"
      expect(page).to have_field "quantity", visible: :all
      expect(page).to have_field "max_quantity", visible: :all
    end

    it "renders the quantity and max quantity of the cart" do
      order = create(:order)
      create(:line_item, order:, variant:, quantity: 2, max_quantity: 4)
      order.line_items.reload

      render_inline(described_class.new(variant:, order:))

      expect(page).to have_button "2"
      expect(page).to have_button "4"
      expect(page).to have_content "in cart"
      expect(page).not_to have_button "Add"
    end
  end

  describe "low stock display" do
    let(:distributor) {
      create(:distributor_enterprise, preferred_product_low_stock_display: true)
    }

    it "shows the remaining stock when low" do
      variant.update!(on_hand: 2)

      render_inline(described_class.new(variant:, order: nil, distributor:))

      expect(page).to have_content "Only 2 items remaining"
    end

    it "doesn't show anything when there is plenty in stock" do
      render_inline(described_class.new(variant:, order: nil, distributor:))

      expect(page).not_to have_content "remaining"
    end

    it "doesn't show anything when the shop doesn't display low stock" do
      variant.update!(on_hand: 2)
      distributor.update!(preferred_product_low_stock_display: false)

      render_inline(described_class.new(variant:, order: nil, distributor:))

      expect(page).not_to have_content "Only 2 items remaining"
    end
  end
end
