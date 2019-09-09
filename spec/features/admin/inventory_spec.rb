require "spec_helper"

feature "Managing inventory", js: true do
  include AdminHelper
  include AuthenticationWorkflow
  include WebHelper

  it "shows more than 100 products" do
    supplier = create(:supplier_enterprise, sells: "own")
    inventory_items = (1..101).map do
      product = create(:simple_product, supplier: supplier)
      InventoryItem.create!(
        enterprise: supplier,
        variant: product.variants.first,
        visible: true
      )
    end
    first_variant = inventory_items.first.variant
    last_variant = inventory_items.last.variant
    first_variant.product.update_attributes!(name: "A First Product")
    last_variant.product.update_attributes!(name: "Z Last Product")
    quick_login_as supplier.users.first
    visit admin_inventory_path

    expect(page).to have_text first_variant.name
    expect(page).to have_selector "tr.product", count: 10
    expect(page).to have_button "Show more"
    expect(page).to have_button "Show all (91  More)"

    click_button "Show all (91  More)"
    expect(page).to have_selector "tr.product", count: 101
    expect(page).to have_text last_variant.name
  end
end
