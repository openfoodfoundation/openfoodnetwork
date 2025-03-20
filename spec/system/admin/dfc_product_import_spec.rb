# frozen_string_literal: false

require 'system_helper'
require_relative '../../../engines/dfc_provider/spec/support/authorization_helper'

RSpec.describe "DFC Product Import" do
  include AuthorizationHelper

  let(:user) { create(:oidc_user, owned_enterprises: [enterprise]) }
  let(:enterprise) { create(:supplier_enterprise, name: "Saucy preserves") }
  let(:source_product) { create(:product, name: "Sauce", supplier_id: enterprise.id) }
  let(:old_product) { create(:product, name: "Best Sauce of 1995", supplier_id: enterprise.id) }

  before do
    login_as user
    source_product # to be imported
    allow(PrivateAddressCheck).to receive(:private_address?).and_return(false)
    user.oidc_account.update!(token: allow_token_for(email: user.email))
  end

  it "imports from given catalog" do
    visit admin_product_import_path

    fill_in "catalog_url", with: "invalid url"
    select enterprise.name, from: "Create products for enterprise"
    click_button "Preview"

    expect(page).to have_content "This catalog URL is not valid"

    # We are testing against our own catalog for now but we want to replace
    # this with the URL of another app when available.
    # We also add a common mistake: copying the URL with an extra space.
    host = Rails.application.default_url_options[:host]
    url = " http://#{host}/api/dfc/enterprises/#{enterprise.id}/catalog_items"
    fill_in "catalog_url", with: url
    select enterprise.name, from: "Create products for enterprise"
    click_button "Preview"

    expect(page).to have_content "Saucy preserves"
    expect(page).to have_content "Sauce - 1g New"

    # By feeding our own catalog to the import, we are effectively cloning the
    # products. But the DFC product references the spree_product_id which
    # make the importer create a variant for that product instead of creating
    # a new independent product.
    expect {
      click_button "Import"
      expect(page).to have_content "Imported products: 1"
    }.to change {
      source_product.variants.count
    }.by(1)
  end

  it "imports from a FDC catalog", vcr: true do
    user.update!(oidc_account: build(:testdfc_account))

    # One current product is existing in OFN
    product_id =
      "https://env-0105831.jcloud-ver-jpe.ik-server.com/api/dfc/Enterprises/test-hodmedod/SuppliedProducts/44519466467635"
    linked_variant = source_product.variants.first
    linked_variant.semantic_links << SemanticLink.new(semantic_id: product_id)

    # One outdated product still exists in OFN
    old_product_id =
      "https://env-0105831.jcloud-ver-jpe.ik-server.com/api/dfc/Enterprises/test-hodmedod/SuppliedProducts/445194664-1995"
    unlinked_variant = old_product.variants.first
    unlinked_variant.semantic_links << SemanticLink.new(semantic_id: old_product_id)
    unlinked_variant.on_demand = true
    unlinked_variant.on_hand = 3

    visit admin_product_import_path

    url = "https://env-0105831.jcloud-ver-jpe.ik-server.com/api/dfc/Enterprises/test-hodmedod/SuppliedProducts"
    fill_in "catalog_url", with: url
    select enterprise.name, from: "Create products for enterprise"
    click_button "Preview"

    expect(page).to have_content "4 products to be imported"
    expect(page).to have_content "One product is no longer"
    expect(page).to have_content "Saucy preserves"
    expect(page).not_to have_content "Sauce - 1g" # Does not show other product
    expect(page).to have_content "Beans - Retail can, 400g (can) Update" # existing product
    expect(page).to have_content "Beans - Case, 12 x 400g (can) New"
    expect(page).to have_content "Chia Seed, Organic - Retail pack, 300g"
    expect(page).to have_content "Best Sauce of 1995 - 1g Reset stock"

    # I can select all
    uncheck "Chia Seed, Organic - Case, 8 x 300g"
    check "Select/deselect all"
    expect(page).to have_checked_field "Chia Seed, Organic - Case, 8 x 300g"

    # And deselect one
    uncheck "Chia Seed, Organic - Case, 8 x 300g"

    expect {
      click_button "Import"
      expect(page).to have_content "Imported products: 3"
      expect(page).to have_content "Stock reset for absent products: 1"
      linked_variant.reload
      unlinked_variant.reload
    }.to change { enterprise.supplied_products.count }.by(2) # 1 updated, 2 new, 1 reset
      .and change { linked_variant.display_name }
      .and change { linked_variant.unit_value }
      # 18.85 wholesale variant price divided by 12 cans in the slab.
      .and change { linked_variant.price }.to(1.57)
      .and change { linked_variant.on_demand }.to(true)
      .and change { linked_variant.on_hand }.by(0)
      .and change { unlinked_variant.on_demand }.to(false)
      .and change { unlinked_variant.on_hand }.by(0)

    product = Spree::Product.last
    expect(product.variants[0].semantic_links).to be_present
    expect(product.image).to be_present

    names = Spree::Product.pluck(:name)
    expect(names).to include "Baked British Beans - Case, 12 x 400g (can)"
    expect(names).not_to include "Chia Seed, Organic - Case, 8 x 300g"
  end

  it "fails gracefully" do
    user.oidc_account.update!(
      uid: "anonymous@example.net",
      updated_at: 1.minute.ago,
    )
    url = "https://example.net/unauthorized"
    stub_request(:get, url).to_return(status: [401, "Unauthorized"])

    visit admin_product_import_path
    select enterprise.name, from: "Create products for enterprise"
    fill_in "catalog_url", with: url

    expect { click_button "Preview" }.not_to change { Spree::Variant.count }

    expect(page).to have_content "the server responded with status 401"

    select enterprise.name, from: "Create products for enterprise"
    fill_in "catalog_url", with: "badurl"
    click_button "Preview"
    expect(page).to have_content "Absolute URI missing hierarchical segment: 'http://:80'"

    select enterprise.name, from: "Create products for enterprise"
    fill_in "catalog_url", with: ""
    click_button "Preview"
    expect(page).to have_content "param is missing or the value is empty: catalog_url"
  end

  it "prompts to refresh OIDC connection", vcr: true do
    # Stale access token will be renewed, but refresh token isn't valid either.
    user.oidc_account.update!(
      refresh_token: "something-expired-or-invalid",
      updated_at: 1.day.ago,
    )

    catalog_url = "https://example.net/unauthorized"
    stub_request(:get, catalog_url).to_return(status: [401, "Unauthorized"])

    visit admin_product_import_path

    select enterprise.name, from: "Create products for enterprise"
    fill_in "catalog_url", with: catalog_url

    click_button "Preview"

    expect(page).to have_content "Product Import"
    expect(page).to have_content "Connecting with your OIDC account failed."
    expect(page).to have_content "Please refresh your OIDC connection at: OIDC Settings"
  end
end
