# frozen_string_literal: true

require 'system_helper'

RSpec.describe 'Tag Rules' do
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

      click_button '+ Add A New Tag'
      fill_in_tag "volunteer"

      # New FilterShippingMethods Rule
      expect(page).to have_content 'No rules apply to this tag yet'
      click_button '+ Add A New Rule'
      tomselect_select 'Show or Hide shipping methods at checkout', from: 'rule_type_selector'
      click_button "Add Rule"
      within("#customer-tag-rule #tr_1001") do
        fill_in_tag "volunteers-only"
        tomselect_select "NOT VISIBLE",
                         from: "enterprise_tag_rules_attributes_1001_preferred_matched_" \
                               "shipping_methods_visibility"
      end

      # New FilterPaymentMethods Rule
      click_button '+ Add A New Rule'
      tomselect_select 'Show or Hide payment methods at checkout', from: 'rule_type_selector'
      click_button "Add Rule"

      # Make sure the dropdown is visible
      scroll_to(:bottom)

      within("#customer-tag-rule #tr_1002") do
        fill_in_tag "volunteers-only2"
        tomselect_select "VISIBLE",
                         from: "enterprise_tag_rules_attributes_1002_preferred_matched_" \
                               "payment_methods_visibility"
      end

      # New FilterOrderCycles Rule
      click_button '+ Add A New Rule'
      tomselect_select 'Show or Hide order cycles in my shopfront', from: 'rule_type_selector'
      click_button "Add Rule"
      within("#customer-tag-rule #tr_1003") do
        fill_in_tag "volunteers-only3"
        tomselect_select "NOT VISIBLE",
                         from: "enterprise_tag_rules_attributes_1003_preferred_matched_" \
                               "order_cycles_visibility"
      end

      # New DEFAULT FilterOrderCycles Rule
      click_button '+ Add A New Default Rule'
      tomselect_select 'Show or Hide order cycles in my shopfront', from: 'rule_type_selector'
      click_button "Add Rule"
      within("#default-tag-rule #tr_0") do
        fill_in_tag "wholesale"
        expect(page).to have_content "not visible"
      end

      click_button 'Update'

      tag_rule = TagRule::FilterShippingMethods.last
      expect(tag_rule.preferred_customer_tags).to eq "volunteer"
      expect(tag_rule.preferred_shipping_method_tags).to eq "volunteers-only"
      expect(tag_rule.preferred_matched_shipping_methods_visibility).to eq "hidden"

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

    context "when inventory enabled", feature: :inventory do
      it "allows creation of filter variant type" do
        # Creating a new tag
        expect(page).to have_content 'No tags apply to this enterprise yet'
        click_button '+ Add A New Tag'
        fill_in_tag "volunteer"

        # New FilterProducts Rule
        click_button '+ Add A New Rule'
        tomselect_select 'Show or Hide variants in my shop', from: 'rule_type_selector'
        click_button "Add Rule"
        within("#customer-tag-rule #tr_1001") do
          fill_in_tag "volunteers-only1"
          tomselect_select "VISIBLE",
                           from: "enterprise_tag_rules_attributes_1001_preferred_matched_" \
                                 "variants_visibility"
        end

        click_button 'Update'

        tag_rule = TagRule::FilterProducts.last
        expect(tag_rule.preferred_customer_tags).to eq "volunteer"
        expect(tag_rule.preferred_variant_tags).to eq "volunteers-only1"
        expect(tag_rule.preferred_matched_variants_visibility).to eq "visible"
      end
    end
  end

  context "updating" do
    let!(:default_fsm_tag_rule) {
      create(:filter_shipping_methods_tag_rule, enterprise:,
                                                preferred_matched_shipping_methods_visibility:
                                                "visible", is_default: true,
                                                preferred_shipping_method_tags: "local" )
    }
    let!(:fp_tag_rule) {
      create(:filter_products_tag_rule, enterprise:,
                                        preferred_matched_variants_visibility:
                                        "visible", preferred_customer_tags: "member",
                                        preferred_variant_tags: "member" )
    }
    let!(:fpm_tag_rule) {
      create(:filter_payment_methods_tag_rule, enterprise:,
                                               preferred_matched_payment_methods_visibility:
                                               "hidden", preferred_customer_tags: "trusted",
                                               preferred_payment_method_tags: "trusted" )
    }
    let!(:foc_tag_rule) {
      create(:filter_order_cycles_tag_rule, enterprise:,
                                            preferred_matched_order_cycles_visibility:
                                            "visible", preferred_customer_tags: "wholesale",
                                            preferred_exchange_tags: "wholesale" )
    }
    let!(:fsm_tag_rule) {
      create(:filter_shipping_methods_tag_rule, enterprise:,
                                                preferred_matched_shipping_methods_visibility:
                                                "hidden", preferred_customer_tags: "local",
                                                preferred_shipping_method_tags: "local" )
    }

    before do
      visit_tag_rules
    end

    it "saves changes to rules of each type" do
      # Tag groups exist
      expect(page).to have_selector '#customer-tag-rule .header', text: "For customers tagged:",
                                                                  count: 4
      expect(page).to have_selector '#customer-tag-rule .header .tags-input .tag-list .tag-item',
                                    text: "member", count: 1
      expect(page).to have_selector '#customer-tag-rule .header .tags-input .tag-list .tag-item',
                                    text: "local", count: 1
      expect(page).to have_selector '#customer-tag-rule .header .tags-input .tag-list .tag-item',
                                    text: "wholesale", count: 1
      expect(page).to have_selector '#customer-tag-rule .header .tags-input .tag-list .tag-item',
                                    text: "trusted", count: 1
      all(:css, "#customer-tag-rule .header .tags-input").each do |node|
        scroll_to(:bottom)
        node.find("li.tag-item a.remove-button").click
        within(:xpath, node.path) { fill_in_tag "volunteer", ".tags input" }
      end

      # DEFAULT FilterShippingMethods rule
      scroll_to(:top)
      within "#default-tag-rule #tr_0" do
        within "li.tag-item", text: "local ×" do
          find("a.remove-button").click
        end
        fill_in_tag "volunteers-only"
        expect(page).to have_content "not visible"
      end

      # FilterProducts rule
      within "#customer-tag-rule #tr_1001" do
        scroll_to(page.find("select.tomselected"))
        within "li.tag-item", text: "member ×" do
          find("a.remove-button").click
        end
        fill_in_tag "volunteers-only1"
        expect(page).to have_select "enterprise_tag_rules_attributes_1001_preferred_matched_" \
                                    "variants_visibility", selected: 'VISIBLE'
        tomselect_select 'NOT VISIBLE',
                         from: "enterprise_tag_rules_attributes_1001_preferred_matched_" \
                               "variants_visibility"
      end

      # FilterPaymentMethods rule
      within "#customer-tag-rule #tr_2001" do
        scroll_to(page.find("select.tomselected"))
        within "li.tag-item", text: "trusted ×" do
          find("a.remove-button").click
        end
        fill_in_tag "volunteers-only2"
        expect(page).to have_select "enterprise_tag_rules_attributes_2001_preferred_matched_" \
                                    "payment_methods_visibility", selected: 'NOT VISIBLE'
        tomselect_select 'VISIBLE',
                         from: "enterprise_tag_rules_attributes_2001_preferred_matched_" \
                               "payment_methods_visibility"
      end

      # FilterOrderCycles rule
      within "#customer-tag-rule #tr_3001" do
        scroll_to(page.find("select.tomselected"))
        within "li.tag-item", text: "wholesale ×" do
          find("a.remove-button").click
        end
        fill_in_tag "volunteers-only3"
        expect(page).to have_select "enterprise_tag_rules_attributes_3001_preferred_matched_" \
                                    "order_cycles_visibility", selected: 'VISIBLE'
        tomselect_select 'NOT VISIBLE',
                         from: "enterprise_tag_rules_attributes_3001_preferred_matched_" \
                               "order_cycles_visibility"
      end

      # FilterShippingMethods rule
      within "#customer-tag-rule #tr_4001" do
        scroll_to(page.find("select.tomselected"))
        within "li.tag-item", text: "local ×" do
          find("a.remove-button").click
        end
        fill_in_tag "volunteers-only4"
        expect(page).to have_select "enterprise_tag_rules_attributes_4001_preferred_matched_" \
                                    "shipping_methods_visibility", selected: 'NOT VISIBLE'
        tomselect_select 'VISIBLE',
                         from: "enterprise_tag_rules_attributes_4001_preferred_matched_" \
                               "shipping_methods_visibility"
      end
    end
  end

  context "deleting" do
    let!(:tag_rule) {
      create(:filter_products_tag_rule, enterprise:, preferred_customer_tags: "member" )
    }
    let!(:default_rule) {
      create(:filter_products_tag_rule, is_default: true, enterprise: )
    }

    before do
      visit_tag_rules
    end

    it "deletes both default and customer rules from the database" do
      expect do
        accept_alert do
          within "#tr_1001" do
            first("a.delete-tag-rule").click
          end
        end
        expect(page).to have_content "Tag Rule has been successfully removed!"
        expect(page).not_to have_selector "#tr_1001"

        accept_alert do
          within "#tr_0" do
            first("a.delete-tag-rule").click
          end
        end
        expect(page).to have_content "Tag Rule has been successfully removed!"
        expect(page).not_to have_selector "#tr_0"
      end.to change{ TagRule.count }.by(-2)
    end
  end

  def visit_tag_rules
    login_as_admin
    visit main_app.edit_admin_enterprise_path(enterprise)
    expect(page).to have_content "PRIMARY DETAILS"
    click_link "Tag Rules"
  end
end
