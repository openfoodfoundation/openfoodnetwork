# frozen_string_literal: false

require 'spec_helper'

module Spree
  describe Image do
    include FileHelper

    let(:product) { create(:product) }

    describe "using local storage" do
      it "stores a new image" do
        image = Spree::Image.create!(
          attachment: black_logo_file,
          viewable: product.master,
        )

        attachment = image.attachment
        expect(attachment.exists?).to eq true
        expect(attachment.file?).to eq true
        expect(attachment.url).to match %r"^/spree/products/[0-9]+/product/logo-black\.png\?[0-9]+$"
      end

      it "duplicates the image with Active Storage" do
        image = Spree::Image.create!(
          attachment: file,
          viewable: product.master,
        )

        attachment = image.active_storage_attachment
        url = Rails.application.routes.url_helpers.url_for(attachment)

        expect(url).to match %r|^http://test\.host/rails/active_storage/blobs/redirect/[[:alnum:]-]+/logo-black\.png$|
      end
    end

    describe "using AWS S3" do
      let(:s3_config) {
        {
          url: ":s3_alias_url",
          storage: :s3,
          s3_credentials: {
            access_key_id: "A...A",
            secret_access_key: "H...H",
          },
          s3_headers: { "Cache-Control" => "max-age=31557600" },
          bucket: "ofn",
          s3_protocol: "https",
          s3_host_alias: "ofn.s3.us-east-1.amazonaws.com",

          # This is for easier testing:
          path: "/:id/:style/:basename.:extension",
        }
      }

      before do
        attachment_definition = Spree::Image.attachment_definitions[:attachment]
        allow(Spree::Image).to receive(:attachment_definitions).and_return(
          attachment: attachment_definition.merge(s3_config)
        )
        allow(Rails.application.config.active_storage).
          to receive(:service).and_return(:test_amazon)
      end

      it "saves a new image when none is present" do
        # Paperclip requests
        upload_pattern = %r"^https://ofn.s3.amazonaws.com/[0-9]+/(original|mini|small|product|large)/logo-black.png$"
        download_pattern = %r"^https://ofn.s3.amazonaws.com/[0-9]+/product/logo-black.png$"
        public_url_pattern = %r"^https://ofn.s3.us-east-1.amazonaws.com/[0-9]+/product/logo-black.png\?[0-9]+$"

        stub_request(:put, upload_pattern).to_return(status: 200, body: "", headers: {})
        stub_request(:head, download_pattern).to_return(status: 200, body: "", headers: {})

        # Active Storage requests
        as_upload_pattern = %r"^https://ofn.s3.amazonaws.com/[[:alnum:]]+$"

        stub_request(:put, as_upload_pattern).to_return(status: 200, body: "", headers: {})

        image = Spree::Image.create!(
          attachment: black_logo_file,
          viewable: product.master,
        )

        # Paperclip
        attachment = image.attachment
        expect(attachment.exists?).to eq true
        expect(attachment.file?).to eq true
        expect(attachment.url).to match public_url_pattern

        # Active Storage
        attachment = image.active_storage_attachment
        expect(attachment).to be_attached
        expect(Rails.application.routes.url_helpers.url_for(attachment)).
          to match %r"^http://test\.host/rails/active_storage/blobs/redirect/[[:alnum:]-]+/logo-black\.png"
      end
    end
  end
end
