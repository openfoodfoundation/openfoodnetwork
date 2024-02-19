# frozen_string_literal: false

require 'system_helper'

describe "DFC Product Import" do
  let(:user) { create(:oidc_user, owned_enterprises: [enterprise]) }
  let(:enterprise) { create(:enterprise) }

  before do
    login_as user
  end

  it "imports from given catalog" do
    visit admin_product_import_path

    fill_in "enterprise_id", with: enterprise.id

    # We are testing against our own catalog for now but we want to replace
    # this with the URL of another app when available.
    fill_in "catalog_url", with: "/api/dfc/enterprises/#{enterprise.id}/supplied_products"

    click_button "Import"

    expect(page).to have_content "Importing a DFC product catalog"
  end
end
