# frozen_string_literal: true

RSpec.describe Spree::Admin::ProductsController do
  include AuthenticationHelper

  let(:user) { create(:enterprise_user) }
  let(:enterprise_id) { user.enterprises.first.id }
  let(:product) { create(:simple_product, name: "Apples", enterprise_id:) }

  before do
    login_as user
  end

  describe "GET /admin/products/:id/edit" do
    it "redirects to current URL" do
      get spree.edit_admin_product_path("#{product.id}-old-apples")

      expect(response).to have_http_status :moved_permanently
      expect(response).to redirect_to("/admin/products/#{product.id}-apples/edit")

      follow_redirect!

      expect(response).to have_http_status :ok
      expect(response.body).to include "Apples"
    end
  end
end
