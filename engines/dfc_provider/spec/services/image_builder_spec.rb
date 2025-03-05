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
end
