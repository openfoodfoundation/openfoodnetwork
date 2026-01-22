# frozen_string_literal: true

RSpec.describe Api::Admin::VariantSerializer do
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
end
