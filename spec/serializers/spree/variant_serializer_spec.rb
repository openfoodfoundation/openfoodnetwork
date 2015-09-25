describe Api::Admin::VariantSerializer do
  let(:variant) { create(:variant) }
  it "serializes a variant" do
    serializer = Api::Admin::VariantSerializer.new variant
    serializer.to_json.should match variant.unit_text
  end
end
