# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Product reports", swagger_doc: "v1.yaml" do
  let!(:supplier) { create(:supplier_enterprise) }
  let!(:other_supplier) { create(:supplier_enterprise) }
  let!(:distributor) { create(:distributor_enterprise) }

  let!(:product) do
    create(:simple_product, enterprise_id: supplier.id)
  end

  let!(:other_cycle_product) do
    create(:simple_product, enterprise_id: supplier.id)
  end

  let!(:hidden_product) do
    create(:simple_product, enterprise_id: other_supplier.id)
  end

  let!(:order_cycle) do
    create(
      :simple_order_cycle,
      coordinator: distributor,
      suppliers: [supplier, other_supplier],
      distributors: [distributor],
      variants: [product.variants.first, hidden_product.variants.first]
    )
  end

  let!(:other_order_cycle) do
    create(
      :simple_order_cycle,
      coordinator: distributor,
      suppliers: [supplier],
      distributors: [distributor],
      variants: [other_cycle_product.variants.first]
    )
  end

  before do
    login_as supplier.owner
  end

  def returned_products
    json_response[:data].map { |row| row[:product] }
  end

  it "filters by order cycle and preserves product visibility" do
    get "/api/v1/reports/products_and_inventory",
        params: { order_cycle_id: order_cycle.id }

    expect(response).to have_http_status(:ok)
    expect(returned_products).to eq([product.name])
  end

  it "filters by distributor across order cycles" do
    get "/api/v1/reports/products_and_inventory",
        params: { distributor_id: distributor.id }

    expect(response).to have_http_status(:ok)
    expect(returned_products).
      to match_array([product.name, other_cycle_product.name])
  end

  it "accepts both filters and an explicit subtype" do
    get "/api/v1/reports/products_and_inventory", params: {
      order_cycle_id: order_cycle.id,
      distributor_id: distributor.id,
      report_subtype: "all_products"
    }

    expect(response).to have_http_status(:ok)
    expect(returned_products).to eq([product.name])
  end

  it "does not apply transaction date filters to products" do
    get "/api/v1/reports/products_and_inventory", params: {
      order_cycle_id: order_cycle.id,
      q: {
        completed_at_gt: "2000-01-01",
        completed_at_lt: "2000-01-02"
      }
    }

    expect(response).to have_http_status(:ok)
    expect(returned_products).to eq([product.name])
  end
end
