require 'spec_helper'

feature "Credit Cards", js: true do
  include AuthenticationWorkflow
  describe "as a logged in user" do
    let(:user) { create(:user) }
    let!(:card) { create(:credit_card, user_id: user.id) }

    before do
      quick_login_as user
    end

    it "lists saved cards, shows interface for adding new cards" do
      visit "/account"

      click_link I18n.t('spree.users.show.tabs.cards')

      expect(page).to have_content I18n.t(:saved_cards)

      within(".card#card#{card.id}") do
        expect(page).to have_content card.cc_type.capitalize
        expect(page).to have_content card.last_digits
      end

      click_button I18n.t(:add_a_card)
      expect(page).to have_field 'first_name'
      expect(page).to have_field 'card_number'
      expect(page).to have_field 'card_month'
    end
  end
end
