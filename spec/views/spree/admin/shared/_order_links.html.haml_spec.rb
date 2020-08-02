require "spec_helper"

describe "spree/admin/shared/_order_links.html.haml" do
  helper Spree::BaseHelper # required to make pretty_time work

  around do |example|
    original_config = Spree::Config[:enable_invoices?]
    example.run
    Spree::Config[:enable_invoices?] = original_config
  end

  before do
    order = create(:completed_order_with_fees)
    assign(:order, order)
  end

  describe "actions dropwdown" do
    it "contains all the actions buttons" do
      render

      expect(rendered).to have_content("links-dropdown")
    end
  end
end
