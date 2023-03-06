# frozen_string_literal: true

require 'system_helper'

describe 'Tag Rules' do
  include AuthenticationHelper
  include WebHelper

  let!(:enterprise) { create(:distributor_enterprise) }

  context "creating" do
    before do
      visit_tag_rules
    end

    it "allows creation of rules of each type" do
      # Creating a new tag
      expect(page).to have_content 'No tags apply to this enterprise yet'
      expect(page).to have_no_selector '.customer_tag'
      click_button '+ Add A New Tag'
      fill_in_tag "volunteer"

      # New FilterShippingMethods Rule
      expect(page).to have_content 'No rules apply to this tag yet'
      click_button '+ Add A New Rule'
      select2_select 'Show or Hide shipping methods at checkout', from: 'rule_type_selector'
      click_button "Add Rule"
      within(".customer_tag #tr_0") do
        fill_in_tag "volunteers-only"
        select2_select "NOT VISIBLE",
                       from: "enterprise_tag_rules_attributes_0_preferred_matched_shipping_methods_visibility"
      end

      # New FilterProducts Rule
      click_button '+ Add A New Rule'
      select2_select 'Show or Hide variants in my shop', from: 'rule_type_selector'
      click_button "Add Rule"
      within(".customer_tag #tr_1") do
        fill_in_tag "volunteers-only1"
        select2_select "VISIBLE",
                       from: "enterprise_tag_rules_attributes_1_preferred_matched_variants_visibility"
      end

      # New FilterPaymentMethods Rule
      click_button '+ Add A New Rule'
      select2_select 'Show or Hide payment methods at checkout', from: 'rule_type_selector'
      click_button "Add Rule"
      within(".customer_tag #tr_2") do
        fill_in_tag "volunteers-only2"
        select2_select "VISIBLE",
                       from: "enterprise_tag_rules_attributes_2_preferred_matched_payment_methods_visibility"
      end

      # New FilterOrderCycles Rule
      click_button '+ Add A New Rule'
      select2_select 'Show or Hide order cycles in my shopfront', from: 'rule_type_selector'
      click_button "Add Rule"
      within(".customer_tag #tr_3") do
        fill_in_tag "volunteers-only3"
        select2_select "NOT VISIBLE",
                       from: "enterprise_tag_rules_attributes_3_preferred_matched_order_cycles_visibility"
      end

      # New DEFAULT FilterOrderCycles Rule
      click_button '+ Add A New Default Rule'
      select2_select 'Show or Hide order cycles in my shopfront', from: 'rule_type_selector'
      click_button "Add Rule"
      within(".default_rules #tr_0") do
        fill_in_tag "wholesale"
        expect(page).to have_content "not visible"
      end

      click_button 'Update'

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
    let!(:default_fsm_tag_rule) {
      create(:filter_shipping_methods_tag_rule, enterprise: enterprise,
                                                preferred_matched_shipping_methods_visibility: "visible", is_default: true, preferred_shipping_method_tags: "local" )
    }
    let!(:fp_tag_rule) {
      create(:filter_products_tag_rule, enterprise: enterprise,
                                        preferred_matched_variants_visibility: "visible", preferred_customer_tags: "member", preferred_variant_tags: "member" )
    }
    let!(:fpm_tag_rule) {
      create(:filter_payment_methods_tag_rule, enterprise: enterprise,
                                               preferred_matched_payment_methods_visibility: "hidden", preferred_customer_tags: "trusted", preferred_payment_method_tags: "trusted" )
    }
    let!(:foc_tag_rule) {
      create(:filter_order_cycles_tag_rule, enterprise: enterprise,
                                            preferred_matched_order_cycles_visibility: "visible", preferred_customer_tags: "wholesale", preferred_exchange_tags: "wholesale" )
    }
    let!(:fsm_tag_rule) {
      create(:filter_shipping_methods_tag_rule, enterprise: enterprise,
                                                preferred_matched_shipping_methods_visibility: "hidden", preferred_customer_tags: "local", preferred_shipping_method_tags: "local" )
    }

    before do
      visit_tag_rules
    end

    it "saves changes to rules of each type" do
      # Tag groups exist
      expect(page).to have_selector '.customer_tag .header', text: "For customers tagged:", count: 4
      expect(page).to have_selector '.customer_tag .header tags-input .tag-list ti-tag-item',
                                    text: "member", count: 1
      expect(page).to have_selector '.customer_tag .header tags-input .tag-list ti-tag-item',
                                    text: "local", count: 1
      expect(page).to have_selector '.customer_tag .header tags-input .tag-list ti-tag-item',
                                    text: "wholesale", count: 1
      expect(page).to have_selector '.customer_tag .header tags-input .tag-list ti-tag-item',
                                    text: "trusted", count: 1
      all(:css, ".customer_tag .header tags-input").each do |node|
        node.find("li.tag-item a.remove-button").click
        within(:xpath, node.path) { fill_in_tag "volunteer", ".tags input" }
      end

      # DEFAULT FilterShippingMethods rule
      within ".default_rules #tr_0" do
        within "li.tag-item", text: "local ✖" do find("a.remove-button").click end
        fill_in_tag "volunteers-only"
        expect(page).to have_content "not visible"
      end

      # FilterProducts rule
      within ".customer_tag #tr_1" do
        within "li.tag-item", text: "member ✖" do find("a.remove-button").click end
        fill_in_tag "volunteers-only1"
        expect(page).to have_select2 "enterprise_tag_rules_attributes_1_preferred_matched_variants_visibility",
                                     selected: 'VISIBLE'
        select2_select 'NOT VISIBLE',
                       from: "enterprise_tag_rules_attributes_1_preferred_matched_variants_visibility"
      end

      # FilterPaymentMethods rule
      within ".customer_tag #tr_2" do
        within "li.tag-item", text: "trusted ✖" do find("a.remove-button").click end
        fill_in_tag "volunteers-only2"
        expect(page).to have_select2 "enterprise_tag_rules_attributes_2_preferred_matched_payment_methods_visibility",
                                     selected: 'NOT VISIBLE'
        select2_select 'VISIBLE',
                       from: "enterprise_tag_rules_attributes_2_preferred_matched_payment_methods_visibility"
      end

      # FilterOrderCycles rule
      within ".customer_tag #tr_3" do
        within "li.tag-item", text: "wholesale ✖" do find("a.remove-button").click end
        fill_in_tag "volunteers-only3"
        expect(page).to have_select2 "enterprise_tag_rules_attributes_3_preferred_matched_order_cycles_visibility",
                                     selected: 'VISIBLE'
        select2_select 'NOT VISIBLE',
                       from: "enterprise_tag_rules_attributes_3_preferred_matched_order_cycles_visibility"
      end

      # FilterShippingMethods rule
      within ".customer_tag #tr_4" do
        within "li.tag-item", text: "local ✖" do find("a.remove-button").click end
        fill_in_tag "volunteers-only4"
        expect(page).to have_select2 "enterprise_tag_rules_attributes_4_preferred_matched_shipping_methods_visibility",
                                     selected: 'NOT VISIBLE'
        select2_select 'VISIBLE',
                       from: "enterprise_tag_rules_attributes_4_preferred_matched_shipping_methods_visibility"
      end
=begin
      # Moving the Shipping Methods to top priority
      find(".customer_tag#tg_4 .header", ).drag_to find(".customer_tag#tg_1 .header")

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
=end
    end
  end

  context "deleting" do
    let!(:tag_rule) {
      create(:filter_products_tag_rule, enterprise: enterprise, preferred_customer_tags: "member" )
    }
    let!(:default_rule) {
      create(:filter_products_tag_rule, is_default: true, enterprise: enterprise )
    }

    before do
      visit_tag_rules
    end

    it "deletes both default and customer rules from the database" do
      expect do
        accept_alert do
          within "#tr_1" do first("a.delete-tag-rule").click end
        end
        expect(page).to have_no_selector "#tr_1"
        accept_alert do
          within "#tr_0" do first("a.delete-tag-rule").click end
        end
        expect(page).to have_no_selector "#tr_0"
      end.to change{ TagRule.count }.by(-2)

      # After deleting tags, the form is dirty and we need to confirm leaving
      # the page. If we don't do it here, Capybara may timeout waiting for the
      # confirmation while resetting the session.
      accept_confirm do
        visit("about:blank")
      end
    end
  end

  def visit_tag_rules
    login_as_admin_and_visit main_app.edit_admin_enterprise_path(enterprise)
    expect(page).to have_content "PRIMARY DETAILS"
    click_link "Tag Rules"
  end
end
