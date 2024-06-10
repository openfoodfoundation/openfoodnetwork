# frozen_string_literal: true

require "spec_helper"

RSpec.describe "/admin/products/:product_id/images", type: :request do
  include AuthenticationHelper

  let!(:product) { create(:product) }

  before do
    login_as_admin
  end

  shared_examples "updating images" do
    let(:params) do
      {
        image: {
          attachment: fixture_file_upload("logo.png", "image/png"),
          viewable_id: product.id,
        }
      }
    end

    it "creates a new image and redirects" do
      expect {
        subject
        product.reload
      }.to change{ product.image&.attachment&.filename.to_s }

      expect(response.status).to eq 302
      expect(response.location).to end_with spree.admin_product_images_path(product)

      expect(product.image.url(:product)).to end_with "logo.png"
    end

    context "with wrong type of file" do
      let(:params) do
        {
          image: {
            attachment: fixture_file_upload("sample_file_120_products.csv", "text/csv"),
            viewable_id: product.id,
          }
        }
      end

      it "responds with an error" do
        expect {
          subject
          product.reload
        }.not_to change{ product.image&.attachment&.filename.to_s }

        expect(response.body).to include "Attachment has an invalid content type"
      end
    end
  end

  describe "POST /admin/products/:product_id/images" do
    subject { post(spree.admin_product_images_path(product), params:) }

    it_behaves_like "updating images"
  end

  describe "PATCH /admin/products/:product_id/images/:id" do
    let!(:product) { create(:product_with_image) }
    subject { patch(spree.admin_product_image_path(product, product.image), params:) }

    it_behaves_like "updating images"
  end
end
