# frozen_string_literal: true

require 'spec_helper'

feature "Credit Cards", js: true do
  include AuthenticationHelper
  include StripeHelper
  include StripeStubs

  describe "as a logged in user" do
    let(:user) { create(:user) }
    let!(:customer) { create(:customer, user: user) }
    let!(:default_card) { create(:stored_credit_card, user_id: user.id, gateway_customer_profile_id: 'cus_AZNMJ', is_default: true) }
    let!(:non_default_card) { create(:stored_credit_card, user_id: user.id, gateway_customer_profile_id: 'cus_FDTG') }

    around do |example|
      original_stripe_connect_enabled = Spree::Config[:stripe_connect_enabled]
      example.run
      Spree::Config.set(stripe_connect_enabled: original_stripe_connect_enabled)
    end

    before do
      login_as user

      Stripe.api_key = "sk_test_12345"
      Stripe.publishable_key = "some_token"
      Spree::Config.set(stripe_connect_enabled: true)

      stub_request(:get, "https://api.stripe.com/v1/customers/cus_AZNMJ").
        to_return(status: 200, body: JSON.generate(id: "cus_AZNMJ"))

      stub_request(:delete, "https://api.stripe.com/v1/customers/cus_AZNMJ").
        to_return(status: 200, body: JSON.generate(deleted: true, id: "cus_AZNMJ"))
      stub_retrieve_payment_method_request("card_1EY...")
      stub_list_customers_request(email: user.email, response: {})
      stub_get_customer_payment_methods_request(customer: "cus_AZNMJ", response: {})
    end

    it "passes the smoke test" do
      visit "/account"

      find("a", :text => %r{#{I18n.t('spree.users.show.tabs.cards')}}i).click

      expect(page).to have_content I18n.t(:saved_cards)

      # Lists saved cards
      within(".card#card#{default_card.id}") do
        expect(page).to have_content default_card.cc_type.capitalize
        expect(page).to have_content default_card.last_digits
        expect(find_field('default_card')).to be_checked
      end

      within(".card#card#{non_default_card.id}") do
        expect(page).to have_content non_default_card.cc_type.capitalize
        expect(page).to have_content non_default_card.last_digits
        expect(find_field('default_card')).to_not be_checked
      end

      # Allows switching of default card
      within(".card#card#{non_default_card.id}") do
        find_field('default_card').click
        accept_alert
        expect(find_field('default_card')).to be_checked
      end

      expect(page).to have_content I18n.t('js.default_card_updated')

      expect(default_card.reload.is_default).to be false
      within(".card#card#{default_card.id}") do
        expect(find_field('default_card')).to_not be_checked
      end
      expect(non_default_card.reload.is_default).to be true

      # Shows the interface for adding a card
      click_button I18n.t(:add_a_card)
      expect(page).to have_field 'first_name'
      expect(page).to have_selector '#card-element.StripeElement'

      # Allows deletion of cards
      within(".card#card#{default_card.id}") do
        click_link I18n.t(:delete)
      end

      expect(page).to have_content I18n.t(:card_has_been_removed, number: "x-#{default_card.last_digits}")
      expect(page).to have_no_selector ".card#card#{default_card.id}"

      # Allows authorisation of card use by shops
      within "tr#customer#{customer.id}" do
        expect(find_field('allow_charges')).to_not be_checked
        find_field('allow_charges').click
      end
      expect(page).to have_content I18n.t('js.changes_saved')
      expect(customer.reload.allow_charges).to be true
    end
  end
end
