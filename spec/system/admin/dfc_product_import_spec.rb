# frozen_string_literal: false

require 'system_helper'
require_relative '../../../engines/dfc_provider/spec/support/authorization_helper'

RSpec.describe "DFC Product Import" do
  include AuthorizationHelper

  let(:user) { create(:oidc_user, owned_enterprises: [enterprise]) }
  let(:enterprise) { create(:supplier_enterprise) }
  let(:source_product) { create(:product, supplier_id: enterprise.id) }

  before do
    login_as user
    source_product # to be imported
    allow(PrivateAddressCheck).to receive(:private_address?).and_return(false)
    user.oidc_account.update!(token: allow_token_for(email: user.email))
  end

  it "imports from given catalog" do
    visit admin_product_import_path

    select enterprise.name, from: "Enterprise"

    # We are testing against our own catalog for now but we want to replace
    # this with the URL of another app when available.
    host = Rails.application.default_url_options[:host]
    url = "http://#{host}/api/dfc/enterprises/#{enterprise.id}/catalog_items"
    fill_in "catalog_url", with: url

    # By feeding our own catalog to the import, we are effectively cloning the
    # products. But the DFC product references the spree_product_id which
    # make the importer create a variant for that product instead of creating
    # a new independent product.
    expect {
      click_button "Import"
    }.to change {
      source_product.variants.count
    }.by(1)

    expect(page).to have_content "Importing a DFC product catalog"
    expect(page).to have_content "Imported products: 1"
  end

  it "imports from a FDC catalog", vcr: true do
    user.oidc_account.update!(
      uid: "testdfc@protonmail.com",
      refresh_token: ENV.fetch("OPENID_REFRESH_TOKEN"),
      updated_at: 1.day.ago,
    )
    product_id =
      "https://env-0105831.jcloud-ver-jpe.ik-server.com/api/dfc/Enterprises/test-hodmedod/SuppliedProducts/44519466467635"
    linked_variant = source_product.variants.first
    linked_variant.semantic_links << SemanticLink.new(semantic_id: product_id)

    visit admin_product_import_path

    select enterprise.name, from: "Enterprise"

    url = "https://env-0105831.jcloud-ver-jpe.ik-server.com/api/dfc/Enterprises/test-hodmedod/SuppliedProducts"
    fill_in "catalog_url", with: url

    expect {
      click_button "Import"
      linked_variant.reload
    }.to change { enterprise.supplied_products.count }
      .and change { linked_variant.display_name }
      .and change { linked_variant.unit_value }
      .and change { linked_variant.price }

    expect(page).to have_content "Importing a DFC product catalog"

    product = Spree::Product.last
    expect(product.variants[0].semantic_links).to be_present
    expect(product.image).to be_present
  end
end
