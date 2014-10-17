require 'spec_helper'

feature %q{
    As an admin
    I want to manage image formats
} do
  include AuthenticationWorkflow
  include WebHelper

  before(:all) do
    styles = {"mini"    => "48x48>",
              "small"   => "100x100>",
              "product" => "240x240>",
              "large"   => "600x600>"}

    Spree::Config[:attachment_styles] = ActiveSupport::JSON.encode(styles)
    Spree::Image.attachment_definitions[:attachment][:styles] = ActiveSupport::JSON.decode(Spree::Config[:attachment_styles])
    Spree::Image.reformat_styles
  end

  scenario "setting the image format for a paperclip style" do
    # When I go to the image settings page
    login_to_admin_section
    visit spree.edit_admin_image_settings_path

    # All the styles should default to "Unchanged"
    page.should have_select 'attachment_styles_format_mini',    selected: 'Unchanged'
    page.should have_select 'attachment_styles_format_small',   selected: 'Unchanged'
    page.should have_select 'attachment_styles_format_product', selected: 'Unchanged'
    page.should have_select 'attachment_styles_format_large',   selected: 'Unchanged'

    # When I change a style to "PNG" and save
    select 'PNG', from: 'attachment_styles_format_mini'
    click_button 'Update'

    # Then the change should be saved to the image formats
    page.should have_content "Image Settings successfully updated."
    page.should have_select 'attachment_styles_format_mini', selected: 'PNG'

    styles = Spree::Image.attachment_definitions[:attachment][:styles]
    styles[:mini].should == ['48x48>', :png]
  end
end
