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
      # Make the whole page visible
      page.driver.resize(1280, 2000)

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
      within(".customer_tag #tr_0") do
        find(:css, "tags-input .tags input").set "volunteers-only\n"
        select2_select "NOT VISIBLE", from: "enterprise_tag_rules_attributes_0_preferred_matched_shipping_methods_visibility"
      end

      # New FilterProducts Rule
      click_button '+ Add A New Rule'
      select2_select 'Show or Hide variants in my shop', from: 'rule_type_selector'
      click_button "Add Rule"
      within(".customer_tag #tr_1") do
        find(:css, "tags-input .tags input").set "volunteers-only1\n"
        select2_select "VISIBLE", from: "enterprise_tag_rules_attributes_1_preferred_matched_variants_visibility"
      end

      # New FilterPaymentMethods Rule
      click_button '+ Add A New Rule'
      select2_select 'Show or Hide payment methods at checkout', from: 'rule_type_selector'
      click_button "Add Rule"
      within(".customer_tag #tr_2") do
        find(:css, "tags-input .tags input").set "volunteers-only2\n"
        select2_select "VISIBLE", from: "enterprise_tag_rules_attributes_2_preferred_matched_payment_methods_visibility"
      end

      # New FilterOrderCycles Rule
      click_button '+ Add A New Rule'
      select2_select 'Show or Hide order cycles in my shopfront', from: 'rule_type_selector'
      click_button "Add Rule"
      within(".customer_tag #tr_3") do
        find(:css, "tags-input .tags input").set "volunteers-only3\n"
        select2_select "NOT VISIBLE", from: "enterprise_tag_rules_attributes_3_preferred_matched_order_cycles_visibility"
      end

      # New DEFAULT FilterOrderCycles Rule
      click_button '+ Add A New Default Rule'
      select2_select 'Show or Hide order cycles in my shopfront', from: 'rule_type_selector'
      click_button "Add Rule"
      within(".default_rules #tr_0") do
        find(:css, "tags-input .tags input").set "wholesale\n"
        expect(page).to have_content "not visible"
      end

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
      expect(tag_rule.preferred_shipping_method_tags).to eq "volunteers-only"
      expect(tag_rule.preferred_matched_shipping_methods_visibility).to eq "hidden"

      tag_rule = TagRule::FilterProducts.last
      expect(tag_rule.preferred_customer_tags).to eq "volunteer"
      expect(tag_rule.preferred_variant_tags).to eq "volunteers-only1"
      expect(tag_rule.preferred_matched_variants_visibility).to eq "visible"

      tag_rule = TagRule::FilterPaymentMethods.last
      expect(tag_rule.preferred_customer_tags).to eq "volunteer"
      expect(tag_rule.preferred_payment_method_tags).to eq "volunteers-only2"
      expect(tag_rule.preferred_matched_payment_methods_visibility).to eq "visible"

      tag_rule = TagRule::FilterOrderCycles.all.reject(&:is_default).last
      expect(tag_rule.preferred_customer_tags).to eq "volunteer"
      expect(tag_rule.preferred_exchange_tags).to eq "volunteers-only3"
      expect(tag_rule.preferred_matched_order_cycles_visibility).to eq "hidden"

      tag_rule = TagRule::FilterOrderCycles.all.select(&:is_default).last
      expect(tag_rule.preferred_customer_tags).to eq ""
      expect(tag_rule.preferred_exchange_tags).to eq "wholesale"
      expect(tag_rule.preferred_matched_order_cycles_visibility).to eq "hidden"
    end
  end

  context "updating" do
    let!(:default_fsm_tag_rule) { create(:filter_shipping_methods_tag_rule, enterprise: enterprise, preferred_matched_shipping_methods_visibility: "visible", is_default: true, preferred_shipping_method_tags: "local" ) }
    let!(:fp_tag_rule) { create(:filter_products_tag_rule, enterprise: enterprise, preferred_matched_variants_visibility: "visible", preferred_customer_tags: "member", preferred_variant_tags: "member" ) }
    let!(:fpm_tag_rule) { create(:filter_payment_methods_tag_rule, enterprise: enterprise, preferred_matched_payment_methods_visibility: "hidden", preferred_customer_tags: "trusted", preferred_payment_method_tags: "trusted" ) }
    let!(:foc_tag_rule) { create(:filter_order_cycles_tag_rule, enterprise: enterprise, preferred_matched_order_cycles_visibility: "visible", preferred_customer_tags: "wholesale", preferred_exchange_tags: "wholesale" ) }
    let!(:fsm_tag_rule) { create(:filter_shipping_methods_tag_rule, enterprise: enterprise, preferred_matched_shipping_methods_visibility: "hidden", preferred_customer_tags: "local", preferred_shipping_method_tags: "local" ) }
    # let!(:do_tag_rule) { create(:tag_rule, enterprise: enterprise, preferred_customer_tags: "member" ) }

    before do
      login_to_admin_section
      visit main_app.edit_admin_enterprise_path(enterprise)
    end

    it "saves changes to rules of each type" do
      # Make the whole page visible
      page.driver.resize(1280, 2000)

      click_link "Tag Rules"

      # Tag groups exist
      expect(page).to have_selector '.customer_tag .header', text: "For customers tagged:", count: 4
      expect(page).to have_selector '.customer_tag .header tags-input .tag-list ti-tag-item', text: "member", count: 1
      expect(page).to have_selector '.customer_tag .header tags-input .tag-list ti-tag-item', text: "local", count: 1
      expect(page).to have_selector '.customer_tag .header tags-input .tag-list ti-tag-item', text: "wholesale", count: 1
      expect(page).to have_selector '.customer_tag .header tags-input .tag-list ti-tag-item', text: "trusted", count: 1
      all(:css, ".customer_tag .header tags-input").each do |node|
        node.find("li.tag-item a.remove-button").trigger('click')
        node.find(".tags input").set "volunteer\n"
      end

      # DEFAULT FilterShippingMethods rule
      within ".default_rules #tr_0" do
        within "li.tag-item", text: "local ✖" do find("a.remove-button").trigger('click') end
        find(:css, "tags-input .tags input").set "volunteers-only\n"
        expect(page).to have_content "not visible"
      end

      # FilterProducts rule
      within ".customer_tag #tr_1" do
        within "li.tag-item", text: "member ✖" do find("a.remove-button").trigger('click') end
        find(:css, "tags-input .tags input").set "volunteers-only1\n"
        expect(page).to have_select2 "enterprise_tag_rules_attributes_1_preferred_matched_variants_visibility", selected: 'VISIBLE'
        select2_select 'NOT VISIBLE', from: "enterprise_tag_rules_attributes_1_preferred_matched_variants_visibility"
      end

      # FilterPaymentMethods rule
      within ".customer_tag #tr_2" do
        within "li.tag-item", text: "trusted ✖" do find("a.remove-button").trigger('click') end
        find(:css, "tags-input .tags input").set "volunteers-only2\n"
        expect(page).to have_select2 "enterprise_tag_rules_attributes_2_preferred_matched_payment_methods_visibility", selected: 'NOT VISIBLE'
        select2_select 'VISIBLE', from: "enterprise_tag_rules_attributes_2_preferred_matched_payment_methods_visibility"
      end

      # FilterOrderCycles rule
      within ".customer_tag #tr_3" do
        within "li.tag-item", text: "wholesale ✖" do find("a.remove-button").trigger('click') end
        find(:css, "tags-input .tags input").set "volunteers-only3\n"
        expect(page).to have_select2 "enterprise_tag_rules_attributes_3_preferred_matched_order_cycles_visibility", selected: 'VISIBLE'
        select2_select 'NOT VISIBLE', from: "enterprise_tag_rules_attributes_3_preferred_matched_order_cycles_visibility"
      end

      # FilterShippingMethods rule
      within ".customer_tag #tr_4" do
        within "li.tag-item", text: "local ✖" do find("a.remove-button").trigger('click') end
        find(:css, "tags-input .tags input").set "volunteers-only4\n"
        expect(page).to have_select2 "enterprise_tag_rules_attributes_4_preferred_matched_shipping_methods_visibility", selected: 'NOT VISIBLE'
        select2_select 'VISIBLE', from: "enterprise_tag_rules_attributes_4_preferred_matched_shipping_methods_visibility"
      end

      # Moving the Shipping Methods to top priority
      find(".customer_tag#tg_4 .header", ).drag_to find(".customer_tag#tg_1 .header")

      # # DiscountOrder rule
      # within "#tr_2" do
      #   expect(page).to have_field "enterprise_tag_rules_attributes_2_calculator_attributes_preferred_flat_percent", with: '0'
      #   fill_in "enterprise_tag_rules_attributes_2_calculator_attributes_preferred_flat_percent", with: 45
      # end

      click_button 'Update'

      # DEFAULT FilterShippingMethods rule
      expect(default_fsm_tag_rule.reload.preferred_customer_tags).to eq ""
      expect(default_fsm_tag_rule.preferred_shipping_method_tags).to eq "volunteers-only"
      expect(default_fsm_tag_rule.preferred_matched_shipping_methods_visibility).to eq "hidden"

      # FilterShippingMethods rule
      expect(fsm_tag_rule.reload.priority).to eq 1
      expect(fsm_tag_rule.preferred_customer_tags).to eq "volunteer"
      expect(fsm_tag_rule.preferred_shipping_method_tags).to eq "volunteers-only4"
      expect(fsm_tag_rule.preferred_matched_shipping_methods_visibility).to eq "visible"

      # FilterProducts rule
      expect(fp_tag_rule.reload.priority).to eq 2
      expect(fp_tag_rule.preferred_customer_tags).to eq "volunteer"
      expect(fp_tag_rule.preferred_variant_tags).to eq "volunteers-only1"
      expect(fp_tag_rule.preferred_matched_variants_visibility).to eq "hidden"

      # FilterPaymentMethods rule
      expect(fpm_tag_rule.reload.priority).to eq 3
      expect(fpm_tag_rule.preferred_customer_tags).to eq "volunteer"
      expect(fpm_tag_rule.preferred_payment_method_tags).to eq "volunteers-only2"
      expect(fpm_tag_rule.preferred_matched_payment_methods_visibility).to eq "visible"

      # FilterOrderCycles rule
      expect(foc_tag_rule.reload.priority).to eq 4
      expect(foc_tag_rule.preferred_customer_tags).to eq "volunteer"
      expect(foc_tag_rule.preferred_exchange_tags).to eq "volunteers-only3"
      expect(foc_tag_rule.preferred_matched_order_cycles_visibility).to eq "hidden"

      # DiscountOrder rule
      # expect(do_tag_rule.preferred_customer_tags).to eq "member,volunteer"
      # expect(do_tag_rule.calculator.preferred_flat_percent).to eq -45
    end
  end

  context "deleting" do
    let!(:tag_rule) { create(:filter_products_tag_rule, enterprise: enterprise, preferred_customer_tags: "member" ) }
    let!(:default_rule) { create(:filter_products_tag_rule, is_default: true, enterprise: enterprise ) }

    before do
      login_to_admin_section
      visit main_app.edit_admin_enterprise_path(enterprise)
    end

    it "deletes both default and customer rules from the database" do
      # Make the whole page visible
      page.driver.resize(1280, 2000)

      click_link "Tag Rules"

      expect do
        within "#tr_1" do first("a.delete-tag-rule").click end
        expect(page).to_not have_selector "#tr_1"
        within "#tr_0" do first("a.delete-tag-rule").click end
        expect(page).to_not have_selector "#tr_0"
      end.to change{TagRule.count}.by(-2)
    end
  end
end
