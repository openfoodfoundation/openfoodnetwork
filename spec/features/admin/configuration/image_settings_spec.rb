require 'spec_helper'

describe "image settings" do
  include AuthenticationHelper

  before do
    login_as_admin_and_visit spree.admin_dashboard_path
    click_link "Configuration"
    click_link "Image Settings"
  end

  # Regression test for #2344
  it "can update attachment_url" do
    fill_in "Attachments URL", with: "foobar"
    fill_in "Attachments Default URL", with: "barfoo"
    fill_in "Attachments Path", with: "spec/dummy/tmp/bfaoro"
    click_button "Update"

    expect(Spree::Config[:attachment_url]).to eq("foobar")
    expect(Spree::Config[:attachment_default_url]).to eq("barfoo")
    expect(Spree::Config[:attachment_path]).to eq("spec/dummy/tmp/bfaoro")
  end

  # Regression test for #3069
  context "updates style configs and uploads products" do
    let!(:product) { create(:product) }
    let(:file_path) { Rails.root + "spec/support/fixtures/thinking-cat.jpg" }

    it "still uploads image gracefully" do
      click_button "Update"

      visit spree.new_admin_product_image_path(product)
      attach_file('image_attachment', file_path)
      expect {
        click_on "Update"
      }.to_not raise_error
    end
  end
end
