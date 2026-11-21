# frozen_string_literal: true

RSpec.describe ProductPreviewRenderer do
  subject(:product_view) { described_class.new(product.reload).product_view }

  let(:producer) { create(:supplier_enterprise, name: "Fred's Farm") }
  # The product's own first variant is the small one
  let(:product) {
    create(:product, name: "Beans", group_buy: true, enterprise_id: producer.id, price: 5,
                     unit_value: 500)
  }
  let!(:small) { product.variants.first.tap { |variant| variant.update!(display_name: "Small") } }
  let!(:large) {
    create(:variant, product:, enterprise: producer, display_name: "Large", price: 8,
                     unit_value: 1000)
  }

  it "describes the product" do
    expect(product_view).to be_a ViewData::Product
    expect(product_view.name).to eq "Beans"
    expect(product_view.group_buy).to be true
    expect(product_view.to_param).to eq product.to_param
  end

  it "includes every variant, in the order they were created" do
    expect(product_view.variants.map(&:id)).to eq [small.id, large.id]
  end

  it "shows the variant's own price, without fees" do
    variant_view = product_view.variants.find { |v| v.id == small.id }

    expect(variant_view.price_with_fees).to eq 5
    expect(variant_view.display_price_with_fees).to eq "$5.00"
    expect(variant_view.fees).to eq []
  end

  it "computes the unit price from that price" do
    variant_view = product_view.variants.find { |v| v.id == small.id }

    expect(variant_view.display_unit_price).to eq "$10.00"
    expect(variant_view.unit_price.unit).to eq "kg"
  end

  it "names the producer" do
    expect(product_view.producers).to eq [producer]
  end
end
