# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe ImageBuilder do
  include FileHelper

  let(:url) { "https://example.net/image.png" }

  before do
    stub_request(:get, url).to_return(status: 200, body: black_logo_path.read)
  end

  describe ".import" do
    it "downloads an image" do
      image = ImageBuilder.import(url)
      expect(image).to be_a Spree::Image
      expect(image.attachment.blob.custom_metadata["origin"]).to eq url
    end
  end

  describe ".apply" do
    let(:product) { create(:product_with_image) }

    it "replaces the image when the URL changes" do
      expect {
        ImageBuilder.apply(url, product)
        product.reload
      }.to change { product.image }
    end

    it "keeps the image when given the URL we serve it at" do
      served_url = product.image.url(:product)
      stub_request(:get, served_url).to_return(status: 200, body: black_logo_path.read)

      expect {
        ImageBuilder.apply(served_url, product)
        product.reload
      }.not_to change { product.image }

      expect(a_request(:get, served_url)).not_to have_been_made
    end
  end
end
