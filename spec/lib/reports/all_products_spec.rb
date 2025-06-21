# frozen_string_literal: true

RSpec.describe Reporting::Reports::ProductsAndInventory::AllProducts do
  let(:user) { create(:admin_user) }
  let(:report) do
    described_class.new user, { fields_to_hide: [] }
  end
  let(:variant) { create(:variant, supplier:) }
  let(:supplier) { create(:supplier_enterprise) }

  it "returns headers" do
    expect(report.table_headers).to eq([
                                         "Supplier",
                                         "Producer Suburb",
                                         "Product",
                                         "Product Properties",
                                         "Taxons",
                                         "Variant Value",
                                         "Price",
                                         "Group Buy Unit Quantity",
                                         "Amount",
                                         "SKU",
                                         "On Demand?",
                                         "On Hand",
                                         "Tax Category"
                                       ])
  end

  it "renders 'On demand' when the product is available on demand" do
    variant.on_demand = true
    variant.on_hand = 15
    variant.save!

    last_row = report.table_rows.last
    on_demand_column = last_row[-3]
    on_hand_column = last_row[-2]

    expect(on_demand_column).to eq("Yes")
    expect(on_hand_column).to eq("On demand")
  end

  it "renders the on hand count when the product is not available on demand" do
    variant.on_demand = false
    variant.on_hand = 22
    variant.save!

    last_row = report.table_rows.last
    on_demand_column = last_row[-3]
    on_hand_column = last_row[-2]

    expect(on_demand_column).to eq("No")
    expect(on_hand_column).to eq(22)
  end

  it "renders tax category if present, otherwise none" do
    variant.update!(tax_category: create(:tax_category, name: 'Test Category'))

    table_rows = report.table_rows
    first_row = table_rows.first # row for default variant, as result of product creation
    last_row = table_rows.last # row for the variant created/updated above

    expect(first_row.last).to eq('none')
    expect(last_row.last).to eq('Test Category')
  end
end
