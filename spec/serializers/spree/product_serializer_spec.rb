describe Api::Admin::ProductSerializer do
  let(:product) { create(:simple_product) }
  it "serializes a product" do
    serializer = Api::Admin::ProductSerializer.new product
    expect(serializer.to_json).to match product.name
  end
end
