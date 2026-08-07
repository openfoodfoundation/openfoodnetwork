# frozen_string_literal: true

RSpec.describe "Admin::ProductPreview" do
  include AuthenticationHelper

  let(:admin_user) { create(:admin_user) }
  let(:headers) { { Accept: "text/vnd.turbo-stream.html" } }
  let(:product) {
    create(
      :simple_product,
      enterprise_id: create(:supplier_enterprise).id,
      description: "<div><br></div><div>Real product description.</div>"
    )
  }

  before { login_as admin_user }

  describe "GET /admin/product_preview/:id" do
    it "strips leading empty blocks from the description" do
      get admin_product_preview_path(product), headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Real product description.")
      expect(response.body).not_to match(%r{<div>\s*<br\s*/?>\s*</div>\s*<div>})
    end
  end
end
