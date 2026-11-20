# frozen_string_literal: true

RSpec.describe "Admin product preview" do
  include AuthenticationHelper

  let(:user) { create(:user) }
  let(:shop) { create(:distributor_enterprise, owner: user) }
  let(:producer) { create(:supplier_enterprise) }
  let(:product) {
    create(:simple_product, name: "Apples", enterprise_id: producer.id, price: 5,
                            variant_unit: "weight", variant_unit_scale: 1000, unit_value: 2000)
  }
  let(:headers) { { Accept: "text/vnd.turbo-stream.html" } }

  before do
    create(:enterprise_relationship, parent: producer, child: shop,
                                     permissions_list: [:manage_products])
    login_as user
  end

  describe "GET /admin/product_preview/:id" do
    it "shows the product like the shop's product modal" do
      get(admin_product_preview_path(product), headers:)

      expect(response).to have_http_status :ok
      expect(response.body).to include "Apples"
      expect(response.body).not_to include "product-page-preview"
    end

    context "when the shop of the user has product pages" do
      before { Flipper.enable("product-pages", shop) }

      it "shows another producer's product like its page" do
        get(admin_product_preview_path(product), headers:)

        expect(response).to have_http_status :ok
        expect(response.body).to include "product-page-preview"

        # The Turbo Stream's template holds the preview.
        template = Nokogiri::HTML.fragment(response.body).at("template")
        page = Capybara::Node::Simple.new(template.inner_html)

        # Without a shop to charge fees, 2kg for $5.00 is $2.50 a kilo.
        expect(page).to have_selector ".prices", text: "$5.00"
        expect(page).to have_selector ".unit-price", text: "$2.50\u00a0/\u00a0kg"
      end
    end

    # Shops show product pages. A producer's flag doesn't change the shops selling its products.
    context "when only the producer has product pages" do
      before { Flipper.enable("product-pages", producer) }

      it "still shows the product like the shop's product modal" do
        get(admin_product_preview_path(product), headers:)

        expect(response.body).not_to include "product-page-preview"
      end
    end
  end
end
