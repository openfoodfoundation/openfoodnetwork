# frozen_string_literal: true

RSpec.describe Api::Admin::VariantSerializer do
  include FileHelper

  let(:variant) { create(:variant) }

  it "serializes the variant name" do
    serializer = Api::Admin::VariantSerializer.new variant

    expect(serializer.to_json).to match variant.name
  end

  it "serializes the variant options" do
    serializer = Api::Admin::VariantSerializer.new variant

    expect(serializer.to_json).to match variant.options_text
  end

  it "serializes the variant full name" do
    serializer = Api::Admin::VariantSerializer.new variant

    expect(serializer.to_json).to match variant.full_name
  end

  describe "#image" do
    before { Spree::Image.create!(attachment: white_logo_file, viewable: variant) }

    it "returns the variant image URL" do
      serializer = Api::Admin::VariantSerializer.new variant.reload

      expect(serializer.image).to eq variant.image_url(:mini)
    end
  end
end
