# frozen_string_literal: true

require 'spec_helper'

describe Api::V0::ProductImagesController, type: :controller do
  include AuthenticationHelper
  include FileHelper
  render_views

  describe "uploading an image" do
    let(:image) { Rack::Test::UploadedFile.new(black_logo_file, 'image/png') }
    let(:pdf) { Rack::Test::UploadedFile.new(pdf_path, 'application/pdf') }
    let(:pdf_path) { Rails.root.join("public/Terms-of-service.pdf") }
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

      expect(response.status).to eq 201
      expect(product_without_image.reload.image.id).to eq json_response['id']
    end

    it "updates an existing product image" do
      post :update_product_image, xhr: true, params: {
        product_id: product_with_image.id, file: image, use_route: :product_images
      }

      expect(response.status).to eq 200
      expect(product_with_image.reload.image.id).to eq json_response['id']
    end

    it "reports errors when saving fails" do
      post :update_product_image, xhr: true, params: {
        product_id: product_without_image.id, file: pdf, use_route: :product_images
      }

      expect(response.status).to eq 422
      expect(product_without_image.image).to be_nil
      expect(json_response["id"]).to eq nil
      expect(json_response["errors"]).to include "Attachment has an invalid content type"
    end
  end
end
