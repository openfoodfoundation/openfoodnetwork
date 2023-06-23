# frozen_string_literal: true

require "spec_helper"

describe "spree/orders/show.html.haml" do
  helper InjectionHelper
  helper ShopHelper
  helper ApplicationHelper
  helper CheckoutHelper
  helper SharedHelper
  helper FooterLinksHelper
  helper MarkdownHelper
  helper TermsAndConditionsHelper

  let(:order) {
    create(
      :completed_order_with_fees,
      number: "R123456789",
    )
  }

  before do
    assign(:order, order)
    allow(view).to receive_messages(
      current_order: order,
      last_payment_method: nil,
    )
  end

  it "shows the order number" do
    render
    expect(rendered).to have_content("R123456789")
  end

  it "shows product images" do
    order.line_items.first.variant.product.image = Spree::Image.new(
      attachment: fixture_file_upload("logo.png", "image/png")
    )

    render

    expect(rendered).to have_css("img[src*='logo.png']")
  end

  it "handles broken images" do
    image, = order.line_items.first.variant.product.image = Spree::Image.new(
      attachment: fixture_file_upload("logo.png", "image/png")
    )
    # This image is not "variable" and can't be resized:
    image.attachment.blob.update!(content_type: "application/octet-stream")

    render

    expect(rendered).to have_css("img[src*='logo.png']")
    expect(rendered).to have_content("R123456789")
  end
end
