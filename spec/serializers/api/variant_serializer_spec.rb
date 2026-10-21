# frozen_string_literal: true

RSpec.describe Api::VariantSerializer do
  include FileHelper

  subject { described_class.new variant }
  let(:variant) { create(:variant, price: 10.00) }

  it "includes the expected attributes" do
    expect(subject.attributes.keys).
      to include(
        :id,
        :name_to_display,
        :on_hand,
        :name_to_display,
        :unit_to_display,
        :unit_value,
        :options_text,
        :on_demand,
        :price,
        :fees,
        :fees_name,
        :price_with_fees,
        :product_name,
        :tag_list, # Used to apply tag rules
        :unit_price_price,
        :unit_price_unit
      )
  end

  describe "#thumb_url" do
    # Reload so images created after the factory are not hidden by cached associations
    subject { described_class.new variant.reload }
    let(:product) { variant.product }

    context "when the variant has its own image" do
      let!(:product_image) { Spree::Image.create!(attachment: black_logo_file, viewable: product) }
      let!(:variant_image) { Spree::Image.create!(attachment: white_logo_file, viewable: variant) }

      it "returns the variant image" do
        expect(subject.thumb_url).to eq variant_image.url(:mini)
      end
    end

    context "when only the product has an image" do
      let!(:product_image) { Spree::Image.create!(attachment: black_logo_file, viewable: product) }

      it "falls back to the product image" do
        expect(subject.thumb_url).to eq product_image.url(:mini)
      end
    end

    context "when neither has an image" do
      it "returns the default image" do
        expect(subject.thumb_url).to eq Spree::Image.default_image_url(:mini)
      end
    end
  end
end
