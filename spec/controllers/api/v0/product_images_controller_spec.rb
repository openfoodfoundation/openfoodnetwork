# frozen_string_literal: true

RSpec.describe Api::V0::ProductImagesController do
  include AuthenticationHelper
  include FileHelper

  render_views

  describe "uploading an image" do
    let(:image) { black_logo_file }
    let(:pdf) { terms_pdf_file }
    let(:product_without_image) { create(:product) }
    let(:product_with_image) { create(:product_with_image) }
    let(:current_api_user) { create(:admin_user) }

    before do
      allow(controller).to receive(:spree_current_user) { current_api_user }
    end

    it "saves a new image when none is present" do
      post :update_product_image, xhr: true, params: {
        product_id: product_without_image.id, file: image, use_route: :product_images
      }

      expect(response).to have_http_status :created
      expect(product_without_image.reload.image.id).to eq json_response['id']
    end

    it "updates an existing product image" do
      post :update_product_image, xhr: true, params: {
        product_id: product_with_image.id, file: image, use_route: :product_images
      }

      expect(response).to have_http_status :ok
      expect(product_with_image.reload.image.id).to eq json_response['id']
    end

    it "reports errors when saving fails" do
      post :update_product_image, xhr: true, params: {
        product_id: product_without_image.id, file: pdf, use_route: :product_images
      }

      expect(response).to have_http_status :unprocessable_entity
      expect(product_without_image.image).to be_nil
      expect(json_response["id"]).to eq nil
      expect(json_response["errors"]).to include "Attachment is " \
                                                 "not identified as a valid media file"
    end
  end
end
