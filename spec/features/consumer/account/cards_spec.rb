require 'spec_helper'

feature "Credit Cards", js: true do
  include AuthenticationWorkflow
  describe "as a logged in user" do
    let(:user) { create(:user) }
    let!(:card) { create(:credit_card, user_id: user.id, gateway_customer_profile_id: 'cus_AZNMJ', is_default: true) }
    let!(:card2) { create(:credit_card, user_id: user.id, gateway_customer_profile_id: 'cus_FDTG') }

    before do
      quick_login_as user

      allow(Stripe).to receive(:api_key) { "sk_test_xxxx" }
      allow(Stripe).to receive(:publishable_key) { "some_token" }
      Spree::Config.set(stripe_connect_enabled: true)

      stub_request(:get, "https://api.stripe.com/v1/customers/cus_AZNMJ").
        to_return(:status => 200, :body => JSON.generate(id: "cus_AZNMJ"))

      stub_request(:delete, "https://api.stripe.com/v1/customers/cus_AZNMJ").
        to_return(:status => 200, :body => JSON.generate(deleted: true, id: "cus_AZNMJ"))
    end

    it "passes the smoke test" do
      visit "/account"

      click_link I18n.t('spree.users.show.tabs.cards')

      expect(page).to have_content I18n.t(:saved_cards)

      # Lists saved cards
      within(".card#card#{card.id}") do
        expect(page).to have_content card.cc_type.capitalize
        expect(page).to have_content card.last_digits
        expect(find_field('default_card')).to be_checked
      end

      within(".card#card#{card2.id}") do
        expect(page).to have_content card2.cc_type.capitalize
        expect(page).to have_content card2.last_digits
        expect(find_field('default_card')).to_not be_checked
      end

      # Allows switching of default card
      within(".card#card#{card2.id}") do
        find_field('default_card').click
        expect(find_field('default_card')).to be_checked
      end

      expect(page).to have_content I18n.t('js.default_card_updated')

      within(".card#card#{card.id}") do
        expect(find_field('default_card')).to_not be_checked
      end
      expect(card.reload.is_default).to be false
      expect(card2.reload.is_default).to be true

      # Shows the interface for adding a card
      click_button I18n.t(:add_a_card)
      expect(page).to have_field 'first_name'
      expect(page).to have_selector '#card-element.StripeElement'

      # Allows deletion of cards
      within(".card#card#{card.id}") do
        click_link I18n.t(:delete)
      end

      expect(page).to have_content I18n.t(:card_has_been_removed, number: "x-#{card.last_digits}")
      expect(page).to_not have_selector ".card#card#{card.id}"
    end
  end
end
