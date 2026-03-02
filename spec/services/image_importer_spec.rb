# frozen_string_literal: false

RSpec.describe ImageImporter do
  let(:ofn_url) { "https://s3.amazonaws.com/ofn_production/eofop2en1y6tu9fr1x9b0wzwgs5r" }
  let(:product) { create(:product) }

  describe "#import" do
    it "downloads from the Internet", :vcr, :aggregate_failures do
      expect {
        subject.import(ofn_url, product)
      }.to change {
        Spree::Image.count
      }.by(1)

      expect(product.image).not_to be_nil
      expect(product.reload.image.attachment_blob.byte_size).to eq 12_926
    end
  end
end
