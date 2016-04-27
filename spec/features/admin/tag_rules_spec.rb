require 'spec_helper'

feature 'Tag Rules', js: true do
  include AuthenticationWorkflow
  include WebHelper

  let!(:enterprise) { create(:distributor_enterprise) }

  context "creating" do
    before do
      login_to_admin_section
      visit main_app.edit_admin_enterprise_path(enterprise)
    end

    it "allows creation of rules of each type" do
      click_link "Tag Rules"

      # Creating a new tag
      expect(page).to_not have_selector '.customer_tag'
      expect(page).to have_content 'No tags apply to this enterprise yet'
      click_button '+ Add A New Tag'
      find(:css, "tags-input .tags input").set "volunteer\n"

      # New FilterShippingMethods Rule
      expect(page).to have_content 'No rules apply to this tag yet'
      click_button '+ Add A New Rule'
      select2_select 'Show or Hide shipping methods at checkout', from: 'rule_type_selector'
      click_button "Add Rule"
      select2_select "NOT VISIBLE", from: "enterprise_tag_rules_attributes_0_preferred_matched_shipping_methods_visibility"

      # New FilterProducts Rule
      click_button '+ Add A New Rule'
      select2_select 'Show or Hide variants in my shop', from: 'rule_type_selector'
      click_button "Add Rule"
      select2_select "VISIBLE", from: "enterprise_tag_rules_attributes_1_preferred_matched_variants_visibility"

      # New FilterPaymentMethods Rule
      click_button '+ Add A New Rule'
      select2_select 'Show or Hide payment methods at checkout', from: 'rule_type_selector'
      click_button "Add Rule"
      select2_select "VISIBLE", from: "enterprise_tag_rules_attributes_2_preferred_matched_payment_methods_visibility"

      # New DiscountOrder Rule
      # click_button '+ Add A New Rule'
      # select2_select 'Apply a discount to orders', from: 'rule_type_selector'
      # click_button "Add Rule"
      # fill_in "enterprise_tag_rules_attributes_1_calculator_attributes_preferred_flat_percent", with: 22

      click_button 'Update'

      # tag_rule = TagRule::DiscountOrder.last
      # expect(tag_rule.preferred_customer_tags).to eq "volunteer"
      # expect(tag_rule.calculator.preferred_flat_percent).to eq -22

      tag_rule = TagRule::FilterShippingMethods.last
      expect(tag_rule.preferred_customer_tags).to eq "volunteer"
      expect(tag_rule.preferred_shipping_method_tags).to eq "volunteer"
      expect(tag_rule.preferred_matched_shipping_methods_visibility).to eq "hidden"

      tag_rule = TagRule::FilterProducts.last
      expect(tag_rule.preferred_customer_tags).to eq "volunteer"
      expect(tag_rule.preferred_variant_tags).to eq "volunteer"
      expect(tag_rule.preferred_matched_variants_visibility).to eq "visible"

      tag_rule = TagRule::FilterPaymentMethods.last
      expect(tag_rule.preferred_customer_tags).to eq "volunteer"
      expect(tag_rule.preferred_payment_method_tags).to eq "volunteer"
      expect(tag_rule.preferred_matched_payment_methods_visibility).to eq "visible"
    end
  end

  context "updating" do
    let!(:do_tag_rule) { create(:tag_rule, enterprise: enterprise, preferred_customer_tags: "member" ) }
    let!(:fsm_tag_rule) { create(:filter_shipping_methods_tag_rule, enterprise: enterprise, preferred_matched_shipping_methods_visibility: "hidden", preferred_customer_tags: "member" ) }
    let!(:fp_tag_rule) { create(:filter_products_tag_rule, enterprise: enterprise, preferred_matched_variants_visibility: "visible", preferred_customer_tags: "member" ) }
    let!(:fpm_tag_rule) { create(:filter_payment_methods_tag_rule, enterprise: enterprise, preferred_matched_payment_methods_visibility: "hidden", preferred_customer_tags: "member" ) }

    before do
      login_to_admin_section
      visit main_app.edit_admin_enterprise_path(enterprise)
    end

    it "saves changes to rules of each type" do
      click_link "Tag Rules"

      # Tag group exists
      expect(first('.customer_tag .header')).to have_content "For customers tagged:"
      expect(first('tags-input .tag-list ti-tag-item')).to have_content "member"
      find(:css, "tags-input .tags input").set "volunteer\n"

      # DiscountOrder rule
      expect(page).to have_field "enterprise_tag_rules_attributes_0_calculator_attributes_preferred_flat_percent", with: '0'
      fill_in "enterprise_tag_rules_attributes_0_calculator_attributes_preferred_flat_percent", with: 45

      # FilterShippingMethods rule
      expect(page).to have_select2 "enterprise_tag_rules_attributes_1_preferred_matched_shipping_methods_visibility", selected: 'NOT VISIBLE'
      select2_select 'VISIBLE', from: "enterprise_tag_rules_attributes_1_preferred_matched_shipping_methods_visibility"

      # FilterProducts rule
      expect(page).to have_select2 "enterprise_tag_rules_attributes_2_preferred_matched_variants_visibility", selected: 'VISIBLE'
      select2_select 'NOT VISIBLE', from: "enterprise_tag_rules_attributes_2_preferred_matched_variants_visibility"

      # FilterPaymentMethods rule
      expect(page).to have_select2 "enterprise_tag_rules_attributes_3_preferred_matched_payment_methods_visibility", selected: 'NOT VISIBLE'
      select2_select 'VISIBLE', from: "enterprise_tag_rules_attributes_3_preferred_matched_payment_methods_visibility"

      click_button 'Update'

      # DiscountOrder rule
      expect(do_tag_rule.preferred_customer_tags).to eq "member,volunteer"
      expect(do_tag_rule.calculator.preferred_flat_percent).to eq -45

      # FilterShippingMethods rule
      expect(fsm_tag_rule.preferred_customer_tags).to eq "member,volunteer"
      expect(fsm_tag_rule.preferred_shipping_method_tags).to eq "member,volunteer"
      expect(fsm_tag_rule.preferred_matched_shipping_methods_visibility).to eq "visible"

      # FilterProducts rule
      expect(fp_tag_rule.preferred_customer_tags).to eq "member,volunteer"
      expect(fp_tag_rule.preferred_variant_tags).to eq "member,volunteer"
      expect(fp_tag_rule.preferred_matched_variants_visibility).to eq "hidden"

      # FilterPaymentMethods rule
      expect(fpm_tag_rule.preferred_customer_tags).to eq "member,volunteer"
      expect(fpm_tag_rule.preferred_payment_method_tags).to eq "member,volunteer"
      expect(fpm_tag_rule.preferred_matched_payment_methods_visibility).to eq "visible"
    end
  end

  context "deleting" do
    let!(:tag_rule) { create(:tag_rule, enterprise: enterprise, preferred_customer_tags: "member" ) }

    before do
      login_to_admin_section
      visit main_app.edit_admin_enterprise_path(enterprise)
    end

    it "deletes rules from the database" do
      click_link "Tag Rules"

      expect(page).to have_selector "#tr_#{tag_rule.id}"

      expect{
        within "#tr_#{tag_rule.id}" do
          first("a.delete-tag-rule").click
        end
        expect(page).to_not have_selector "#tr_#{tag_rule.id}"
      }.to change{TagRule.count}.by(-1)
    end
  end
end
