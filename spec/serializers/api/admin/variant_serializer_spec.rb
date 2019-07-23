describe Api::Admin::VariantSerializer do
  let(:variant) { create(:variant) }
  it "serializes a variant" do
    serializer = Api::Admin::VariantSerializer.new variant
    expect(serializer.to_json).to match variant.options_text
  end
end
