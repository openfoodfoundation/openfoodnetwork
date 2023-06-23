# frozen_string_literal: false

require 'spec_helper'

describe ImageImporter do
  let(:url) { Rails.root.join("spec/fixtures/files/logo.png").to_s }
  let(:product) { create(:product) }

  describe "#import" do
    it "downloads and attaches to the product" do
      expect {
        subject.import(url, product)
      }.to change {
        Spree::Image.count
      }.by(1)

      expect(product.image).to_not be_nil
      expect(product.reload.image.attachment_blob.byte_size).to eq 6274
    end
  end
end
