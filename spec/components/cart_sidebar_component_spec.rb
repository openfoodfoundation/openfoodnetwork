# frozen_string_literal: true

RSpec.describe CartSidebarComponent, type: :component do
  context "without an order" do
    it "renders an empty cart" do
      render_inline(described_class.new(order: nil))

      expect(page).to have_selector "#cart-sidebar"
      expect(page).to have_content "Your cart is empty"
      expect(page).to have_link "Take me shopping!"
      expect(page).not_to have_selector "tr.product-cart"
      expect(page).not_to have_link "Checkout"
    end
  end

  context "with an order with line items" do
    let(:order) { create(:order_with_line_items, line_items_count: 1) }
    let(:line_item) { order.line_items.first }

    it "renders the line items with quantity and price" do
      render_inline(described_class.new(order:))

      expect(page).to have_content "1 item in your cart"
      expect(page).to have_selector "tr#cart-variant-#{line_item.variant_id}"
      expect(page).to have_selector ".quantity", text: line_item.quantity.to_s
      expect(page).to have_selector(
        ".total-price", text: line_item.display_amount_with_adjustments.to_s
      )
      expect(page).not_to have_content "Your cart is empty"
    end

    it "renders the footer with total and links" do
      render_inline(described_class.new(order:))

      expect(page).to have_content "Total"
      expect(page).to have_link "Edit cart", href: "/cart"
      expect(page).to have_link "Checkout", href: "/checkout"
    end

    it "pluralizes the item count" do
      create(:line_item, order:, quantity: 2)
      order.line_items.reload

      render_inline(described_class.new(order:))

      expect(page).to have_content(
        "#{order.line_items.sum(:quantity)} items in your cart"
      )
    end
  end
end
