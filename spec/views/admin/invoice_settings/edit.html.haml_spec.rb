# frozen_string_literal: true

RSpec.describe "admin/invoice_settings/edit.html.haml" do
  helper Spree::Admin::NavigationHelper

  before do
    stub_template "spree/admin/shared/_configuration_menu.html.haml" => ""
    allow(view).to receive(:spree_current_user).and_return(build(:user))
    allow(OpenFoodNetwork::FeatureToggle).to receive(:enabled?).and_return(false)
  end

  it "has labels correctly associated with their checkboxes" do
    render

    expect(rendered).to have_css('label[for="preferences_enable_invoices_"]')
    expect(rendered).to have_css('input[id="preferences_enable_invoices_"]')

    expect(rendered).to have_css('label[for="preferences_invoice_style2_"]')
    expect(rendered).to have_css('input[id="preferences_invoice_style2_"]')

    expect(rendered).to have_css('label[for="preferences_enterprise_number_required_on_invoices_"]')
    expect(rendered).to have_css('input[id="preferences_enterprise_number_required_on_invoices_"]')
  end
end
