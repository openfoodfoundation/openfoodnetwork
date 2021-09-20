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

      expect(product.images.count).to eq 1
      expect(product.images.first.attachment.size).to eq 6274
    end
  end
end
