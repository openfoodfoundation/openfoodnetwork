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

    it "creates a new rule" do
      click_link "Tag Rules"

      expect(page).to_not have_selector '.customer_tag'
      expect(page).to have_content 'No tags apply to this enterprise yet'
      click_button '+ Add A New Tag'
      find(:css, "tags-input .tags input").set "volunteer\n"

      expect(page).to have_content 'No rules apply to this tag yet'
      click_button '+ Add A New Rule'
      fill_in "enterprise_tag_rules_attributes_0_calculator_attributes_preferred_flat_percent", with: 22

      click_button 'Update'

      tag_rule = TagRule::DiscountOrder.last
      expect(tag_rule.preferred_customer_tags).to eq "volunteer"
      expect(tag_rule.calculator.preferred_flat_percent).to eq -22
    end
  end

  context "updating" do
    let!(:tag_rule) { create(:tag_rule, enterprise: enterprise, preferred_customer_tags: "member" ) }

    before do
      login_to_admin_section
      visit main_app.edit_admin_enterprise_path(enterprise)
    end

    it "saves changes to the rule" do
      click_link "Tag Rules"

      expect(first('.customer_tag .header')).to have_content "For customers tagged:"
      expect(first('tags-input .tag-list ti-tag-item')).to have_content "member"
      find(:css, "tags-input .tags input").set "volunteer\n"
      expect(page).to have_field "enterprise_tag_rules_attributes_0_calculator_attributes_preferred_flat_percent", with: '0'
      fill_in "enterprise_tag_rules_attributes_0_calculator_attributes_preferred_flat_percent", with: 45

      click_button 'Update'

      expect(tag_rule.preferred_customer_tags).to eq "member,volunteer"
      expect(tag_rule.calculator.preferred_flat_percent).to eq -45
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
