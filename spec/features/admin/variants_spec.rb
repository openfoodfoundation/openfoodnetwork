require "spec_helper"

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
    click_link 'Products'
    within('#sub_nav') { click_link 'Products' }
    click_link p.name
    click_link 'Variants'
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

  it "does not show unit value or description fields when the product does not have a unit-related option type" do
    # Given a product without unit-related option types, with a variant
    p = create(:simple_product, variant_unit: nil, variant_unit_scale: nil)
    v = create(:variant, product: p, unit_value: nil, unit_description: nil)

    # And the product has option types for the variant's option values
    p.option_types << v.option_values.first.option_type

    # When I view the variant
    login_to_admin_section
    click_link 'Products'
    within('#sub_nav') { click_link 'Products' }
    click_link p.name
    click_link 'Variants'
    page.find('table.index .icon-edit').click

    # Then I should not see unit value and description fields
    page.should_not have_field "variant_unit_value"
    page.should_not have_field "variant_unit_description"
  end


  context "as an enterprise user" do
    before(:each) do
      @new_user = create_enterprise_user
      @supplier = create(:supplier_enterprise)
      @new_user.enterprise_roles.build(enterprise: @supplier).save

      login_to_admin_as @new_user
    end

    scenario "deleting product properties", js: true do
      # Given a product with a property
      p = create(:simple_product, supplier: @supplier)
      p.set_property('fooprop', 'fooval')

      # When I navigate to the product properties page
      visit spree.admin_product_product_properties_path(p)
      page.should have_field 'product_product_properties_attributes_0_property_name', with: 'fooprop', visible: true
      page.should have_field 'product_product_properties_attributes_0_value', with: 'fooval', visible: true

      # And I delete the property
      page.all('a.remove_fields').first.click
      wait_until { p.reload.property('fooprop').nil? }

      # Then the property should have been deleted
      page.should_not have_field 'product_product_properties_attributes_0_property_name', with: 'fooprop', visible: true
      page.should_not have_field 'product_product_properties_attributes_0_value', with: 'fooval', visible: true
    end
  end
end
