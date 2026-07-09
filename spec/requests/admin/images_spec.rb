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

    context "when attachment is not provided" do
      let(:params) do
        {
          image: {
            viewable_id: product.id,
            alt: "Updated alt text",
          }
        }
      end

      it "updates image metadata in place" do
        expect {
          subject
          product.reload
        }.not_to change { Spree::Image.count }

        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(spree.admin_product_images_path(product))
        expect(product.image.alt).to eq("Updated alt text")
      end
    end
  end

  describe "PATCH /admin/products/:product_id/images/:id with turbo" do
    let!(:product) { create(:product_with_image) }
    subject {
      patch(spree.admin_product_image_path(product, product.image), params:, as: :turbo_stream)
    }

    it_behaves_like "updating images", 200
  end

  describe "POST /admin/products/:product_id/images with variant_id" do
    let(:variant) { create(:variant, product:) }
    let(:params) do
      {
        image: {
          attachment: fixture_file_upload("logo.png", "image/png"),
          viewable_id: variant.id,
        },
        variant_id: variant.id,
      }
    end
    subject { post(spree.admin_product_images_path(product), params:) }

    it "creates a new image for the variant" do
      expect {
        subject
        variant.reload
      }.to change { variant.image&.attachment&.filename.to_s }

      expect(variant.image.viewable_type).to eq "Spree::Variant"
      expect(variant.image.viewable_id).to eq variant.id
    end

    it "redirects to admin_products_url" do
      subject
      expect(response).to have_http_status :found
      expect(response.location).to end_with spree.admin_products_path
    end

    context "with wrong type of file" do
      let(:params) do
        {
          image: {
            attachment: fixture_file_upload("sample_file_120_products.csv", "text/csv"),
            viewable_id: variant.id,
          },
          variant_id: variant.id,
        }
      end

      it "responds with an error" do
        expect {
          subject
          variant.reload
        }.not_to change { variant.image&.attachment&.filename.to_s }

        expect(response.body).to include "Attachment has an invalid content type"
      end
    end
  end

  describe "PATCH /admin/products/:product_id/images/:id with variant_id" do
    let(:variant) { create(:variant, product:) }
    let!(:variant_image) {
      Spree::Image.create(
        attachment: fixture_file_upload("logo.png", "image/png"),
        viewable_id: variant.id,
        viewable_type: 'Spree::Variant'
      )
    }
    let(:params) do
      {
        image: {
          attachment: fixture_file_upload("thinking-cat.jpg", "image/jpeg"),
          viewable_id: variant.id,
        },
        variant_id: variant.id,
      }
    end
    subject {
      patch(spree.admin_product_image_path(product, variant_image), params:)
    }

    it "updates the variant image" do
      expect {
        subject
        variant.reload
      }.to change { variant.image&.attachment&.filename.to_s }

      expect(variant.image.viewable_type).to eq "Spree::Variant"
      expect(variant.image.viewable_id).to eq variant.id
    end

    it "redirects to admin_products_url" do
      subject
      expect(response).to have_http_status :found
      expect(response.location).to end_with spree.admin_products_path
    end
  end
end
