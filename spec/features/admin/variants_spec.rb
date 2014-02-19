require "spec_helper"

feature %q{
    As an admin
    I want to manage product variants
} do
  include AuthenticationWorkflow
  include WebHelper

  scenario "editing unit value and description for a variant" do
    # Given a product with unit-related option types, with a variant
    p = create(:simple_product, variant_unit: "weight", variant_unit_scale: "1")
    v = create(:variant, product: p, unit_value: 1, unit_description: 'foo')

    # And the product has option types for the unit-related and non-unit-related option values
    p.option_types << v.option_values.first.option_type

    # When I view the variant
    login_to_admin_section
    click_link 'Products'
    within('#sub_nav') { click_link 'Products' }
    click_link p.name
    click_link 'Variants'
    page.find('table.index .icon-edit').click

    # Then I should not see a traditional option value field for the unit-related option value
    page.all("div[data-hook='presentation'] input").count.should == 1

    # And I should see unit value and description fields for the unit-related option value
    page.should have_field "variant_unit_value", with: "1"
    page.should have_field "variant_unit_description", with: "foo"

    # When I update the fields and save the variant
    fill_in "variant_unit_value", with: "123"
    fill_in "variant_unit_description", with: "bar"
    click_button 'Update'
    page.should have_content %Q(Variant "#{p.name}" has been successfully updated!)

    # Then the unit value and description should have been saved
    v.reload
    v.unit_value.should == 123
    v.unit_description.should == 'bar'
  end

  it "should not show unit value or description fields when the product does not have a unit-related option type"
end
