# frozen_string_literal: true

RSpec.describe "/admin/products/:product_id/images" do
  include AuthenticationHelper

  let!(:product) { create(:product) }

  before do
    login_as_admin
  end

  shared_examples "updating images" do |expected_http_status_code|
    let(:params) do
      {
        image: {
          attachment: fixture_file_upload("logo.png", "image/png"),
          viewable_id: product.id,
        }
      }
    end

    it "creates a new image and redirects unless called by turbo" do
      expect {
        subject
        product.reload
      }.to change{ product.image&.attachment&.filename.to_s }

      expect(response.status).to eq expected_http_status_code
      if expected_http_status_code == 302
        expect(response.location).to end_with spree.admin_product_images_path(product)
      end

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

    it_behaves_like "updating images", 302
  end

  describe "POST /admin/products/:product_id/images with turbo" do
    subject { post(spree.admin_product_images_path(product), params:, as: :turbo_stream) }

    it_behaves_like "updating images", 200
  end

  describe "PATCH /admin/products/:product_id/images/:id" do
    let!(:product) { create(:product_with_image) }
    subject {
      patch(spree.admin_product_image_path(product, product.image), params:)
    }

    it_behaves_like "updating images", 302
  end

  describe "PATCH /admin/products/:product_id/images/:id with turbo" do
    let!(:product) { create(:product_with_image) }
    subject {
      patch(spree.admin_product_image_path(product, product.image), params:, as: :turbo_stream)
    }

    it_behaves_like "updating images", 200
  end
end
