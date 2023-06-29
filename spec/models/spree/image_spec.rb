# frozen_string_literal: false

require 'spec_helper'

module Spree
  describe Image do
    include FileHelper

    subject {
      Spree::Image.create!(
        attachment: black_logo_file,
        viewable: product,
      )
    }
    let(:product) { create(:product) }

    describe "#url" do
      it "returns URLs for different sizes" do
        expect(subject.url(:small)).to match(
          %r|^http://test\.host/rails/active_storage/representations/redirect/.+/logo-black\.png$|
        )
      end

      it "returns download link for unsupported formats" do
        subject.attachment_blob.update_columns(
          content_type: "application/octet-stream"
        )

        expect(subject.url(:small)).to match(
          %r|^http://test\.host/rails/active_storage/blobs/redirect/.+/logo-black\.png$|
        )
      end

      it "returns default image when the attachment is missing" do
        subject.attachment = nil

        expect(subject.url(:small)).to eq "/noimage/small.png"
      end

      context "when no image attachment is found" do
        it "returns a default product image" do
          expect(subject).to receive_message_chain(:attachment, :attached?) { false }

          expect(subject.url(:mini)).to eq "/noimage/mini.png"
        end
      end

      context "when accessing the image raises an ActiveStorage error" do
        it "rescues the error and returns a default product image" do
          expect(subject).to receive(:attachment) { raise ActiveStorage::FileNotFoundError }

          expect(subject.url(:small)).to eq "/noimage/small.png"
        end
      end

      context "when using public images" do
        it "returns the direct URL for the processed image" do
          allow(ENV).to receive(:[])
          expect(ENV).to receive(:[]).with("S3_BUCKET").and_return("present")

          variant = double(:variant)
          allow(subject).to receive_message_chain(:attachment, :attached?) { true }
          expect(subject).to receive(:variant) { variant }
          expect(variant).to receive_message_chain(:service, :public?) { true }
          expect(variant).to receive_message_chain(:processed, :url) { "https://ofn-s3/123.png" }

          expect(subject.url(:small)).to eq "https://ofn-s3/123.png"
        end
      end
    end

    describe "#default_image_url" do
      it "returns default product image for a given size" do
        expect(subject.class.default_image_url(:mini)).to eq "/noimage/mini.png"
      end

      it "returns default product image when no size is given" do
        expect(subject.class.default_image_url(nil)).to eq "/noimage/product.png"
      end
    end

    describe "using local storage" do
      it "stores a new image" do
        attachment = subject.attachment
        expect(attachment.attached?).to eq true

        url = Rails.application.routes.url_helpers.url_for(attachment)
        expect(url).to match %r|^http://test\.host/rails/active_storage/blobs/redirect/[[:alnum:]-]+/logo-black\.png$|
      end
    end

    describe "using AWS S3" do
      before do
        allow(Rails.application.config.active_storage).
          to receive(:service).and_return(:test_amazon)
      end

      it "saves a new image when none is present" do
        # Active Storage requests
        as_upload_pattern = %r"^https://ofn.s3.amazonaws.com/[[:alnum:]]+$"

        stub_request(:put, as_upload_pattern).to_return(status: 200, body: "", headers: {})

        expect(subject.attachment).to be_attached
        expect(Rails.application.routes.url_helpers.url_for(subject.attachment)).
          to match %r"^http://test\.host/rails/active_storage/blobs/redirect/[[:alnum:]-]+/logo-black\.png"
      end
    end
  end
end
