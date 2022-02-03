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
        expect(attachment.url).to match /logo-black\.png\?[0-9]+$/
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
      around do |example|
        original_config = Spree::Image.attachment_definitions
        test_config = original_config.dup
        test_config[:attachment].merge!(s3_config)
        Spree::Image.attachment_definitions = test_config

        example.run

        Spree::Image.attachment_definitions = original_config
      end

      it "saves a new image when none is present" do
        pending "patch for aws-sdk to encode URIs"

        stub_request(:put, %r"https://ofn.s3.amazonaws.com/[0-9]+/(original|mini|small|product|large)/logo-black.png").
          to_return(status: 200, body: "", headers: {})
        stub_request(:head, %r"https://ofn.s3.amazonaws.com/[0-9]+/product/logo-black.png").
          to_return(status: 200, body: "", headers: {})
        image = Spree::Image.create!(
          attachment: file,
          viewable: product.master,
        )

        attachment = image.attachment
        expect(attachment.exists?).to eq true
        expect(attachment.file?).to eq true
        expect(attachment.url).to match /logo-black\.png\?[0-9]+$/
      end
    end
  end
end
