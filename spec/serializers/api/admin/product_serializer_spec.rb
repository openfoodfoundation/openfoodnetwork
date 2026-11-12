# frozen_string_literal: true

RSpec.describe Api::Admin::ProductSerializer do
  include FileHelper

  let(:product) { create(:simple_product, enterprise_id: create(:supplier_enterprise).id) }
  let(:serializer) { described_class.new(product) }

  it "serializes a product" do
    expect(serializer.to_json).to match(product.name)
  end

  describe "#variants" do
    let(:variant) { product.variants.first }
    let(:other_variant) { create(:variant, product:) }

    before do
      Spree::Image.create!(attachment: black_logo_file, viewable: product)
      Spree::Image.create!(attachment: white_logo_file, viewable: variant)
      other_variant
      product.reload
    end

    it "serializes each variant's own image, falling back to the product image" do
      images = serializer.variants.as_json.to_h { |v| [v[:id], v[:image]] }

      expect(images).to eq(
        variant.id => variant.image.url(:mini),
        other_variant.id => product.image.url(:mini),
      )
    end
  end
end
