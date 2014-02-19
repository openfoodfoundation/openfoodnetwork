require "spec_helper"

feature %q{
    As an admin
    I want to manage product variants
} do
  include AuthenticationWorkflow
  include WebHelper

  describe "units and values" do
    it "does not show traditional option value fields for unit-related option types" do
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
    end

    it "shows unit value and description fields when the variant's product has associated option types set"
  end
end
