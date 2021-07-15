# frozen_string_literal: false

require 'spec_helper'

describe ImageImporter do
  describe ImageImporter::URIValidator do
    describe ".validate!" do
      it "refuses local paths" do
        expect {
          subject.validate!("file:///etc/passwd")
        }.to raise_error "Connection not protected"
      end

      it "refuses unknown domains" do
        expect {
          subject.validate!("https://example.com")
        }.to raise_error "Domain not allowed"
      end

      it "allows known domains" do
        expect {
          subject.validate!("https://cdn.digitaloceanspaces.com/image")
        }.to_not raise_error
      end

      it "allows subdomains of known domains" do
        expect {
          subject.validate!("https://example.cdn.digitaloceanspaces.com/image")
        }.to_not raise_error
      end
    end
  end

  describe "#import" do
    let(:image) { Rails.root.join("spec/fixtures/files/promo.png") }
    let(:url) {
      "https://images-originals.sgp1.cdn.digitaloceanspaces.com/Market/Stalls/297/img-2508.png"
    }
    let(:product) { create(:product) }

    before do
      stub_request(:get, url).
        to_return(
          status: 200,
          body: image.read,
        )
    end

    it "downloads and attaches to the product" do
      subject.import(url, product)

      expect(product.images.size).to eq 1
      expect(product.images.first.attachment.size).to eq 4511
    end

    it "attaches without saving to the database" do
      expect {
        subject.import(url, product)
      }.to_not change {
        Spree::Image.count
      }

      expect {
        product.master.save!
      }.to change {
        Spree::Image.count
      }.by(1)
    end
  end
end
