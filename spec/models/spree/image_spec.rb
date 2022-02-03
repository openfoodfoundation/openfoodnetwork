# frozen_string_literal: false

require 'spec_helper'

module Spree
  describe Image do
    include FileHelper

    let(:file) { Rack::Test::UploadedFile.new(black_logo_file, 'image/png') }
    let(:product) { create(:product) }

    describe "using local storage" do
      it "stores a new image" do
        image = Spree::Image.create!(
          attachment: file,
          viewable: product.master,
        )

        attachment = image.attachment
        expect(attachment.exists?).to eq true
        expect(attachment.file?).to eq true
        expect(attachment.url).to match %r"^/spree/products/[0-9]+/product/logo-black\.png\?[0-9]+$"
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
      end

      it "saves a new image when none is present" do
        upload_pattern = %r"^https://ofn.s3.amazonaws.com/[0-9]+/(original|mini|small|product|large)/logo-black.png$"
        download_pattern = %r"^https://ofn.s3.amazonaws.com/[0-9]+/product/logo-black.png$"
        public_url_pattern = %r"^https://ofn.s3.us-east-1.amazonaws.com/[0-9]+/product/logo-black.png\?[0-9]+$"

        stub_request(:put, upload_pattern).to_return(status: 200, body: "", headers: {})
        stub_request(:head, download_pattern).to_return(status: 200, body: "", headers: {})

        image = Spree::Image.create!(
          attachment: file,
          viewable: product.master,
        )

        attachment = image.attachment
        expect(attachment.exists?).to eq true
        expect(attachment.file?).to eq true
        expect(attachment.url).to match public_url_pattern
      end
    end
  end
end
