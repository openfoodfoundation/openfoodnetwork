require 'spec_helper'

feature %q{
    As an admin
    I want to manage product variants
} do
  include AuthenticationWorkflow
  include WebHelper

  scenario "creating a new variant" do
    # Given a product with a unit-related option type
    p = create(:simple_product, variant_unit: "weight", variant_unit_scale: "1")

    # When I create a variant on the product
    login_to_admin_section
    visit spree.admin_product_variants_path p
    click_link 'New Variant'

    fill_in 'variant_unit_value', with: '1'
    fill_in 'variant_unit_description', with: 'foo'
    click_button 'Create'

    # Then the variant should have been created
    page.should have_content "Variant \"#{p.name}\" has been successfully created!"
  end


  scenario "editing unit value and description for a variant" do
    # Given a product with unit-related option types, with a variant
    p = create(:simple_product, variant_unit: "weight", variant_unit_scale: "1")
    v = create(:variant, product: p, unit_value: 1, unit_description: 'foo')

    # And the product has option types for the unit-related and non-unit-related option values
    p.option_types << v.option_values.first.option_type

    # When I view the variant
    login_to_admin_section
    visit spree.admin_product_variants_path p
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

  it "does not show unit value or description fields when the product does not have a unit-related option type" do
    # Given a product without unit-related option types, with a variant
    p = create(:simple_product, variant_unit: nil, variant_unit_scale: nil)
    v = create(:variant, product: p, unit_value: nil, unit_description: nil)

    # And the product has option types for the variant's option values
    p.option_types << v.option_values.first.option_type

    # When I view the variant
    login_to_admin_section
    visit spree.admin_product_variants_path p
    page.find('table.index .icon-edit').click

    # Then I should not see unit value and description fields
    page.should_not have_field "variant_unit_value"
    page.should_not have_field "variant_unit_description"
  end

  it "soft-deletes variants", js: true do
    p = create(:simple_product)
    v = create(:variant, product: p)

    login_to_admin_section
    visit spree.admin_product_variants_path p

    page.find('a.delete-resource').click
    page.should_not have_content v.options_text

    v.reload
    v.deleted_at.should_not be_nil
  end
end
