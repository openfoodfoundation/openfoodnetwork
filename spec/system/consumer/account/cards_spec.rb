# frozen_string_literal: true

require 'system_helper'

describe "Credit Cards" do
  include AuthenticationHelper
  include StripeHelper
  include StripeStubs

  describe "as a logged in user" do
    let(:user) { create(:user) }
    let!(:customer) { create(:customer, user: user, created_manually: true) }
    let!(:default_card) {
      create(:stored_credit_card, user_id: user.id, gateway_customer_profile_id: 'cus_AZNMJ',
                                  is_default: true)
    }
    let!(:non_default_card) {
      create(:stored_credit_card, user_id: user.id, gateway_customer_profile_id: 'cus_FDTG')
    }

    before do
      login_as user

      allow(Stripe).to receive(:api_key).and_return("sk_test_12345")
      allow(Stripe.config).to receive(:api_key).and_return("sk_test_12345")
      allow(Stripe).to receive(:publishable_key).and_return("some_token")
      allow(Spree::Config).to receive(:stripe_connect_enabled).and_return(true)

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

      find("a", text: /Credit Cards/i).click

      expect(page).to have_content 'Saved cards'

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
      alert_text = <<~TEXT.strip
        Changing your default card will remove shops' existing authorizations \
        to charge it. You can re-authorize shops after updating the default \
        card. Do you wish to change the default card?
      TEXT
      within(".card#card#{non_default_card.id}") do
        accept_alert(alert_text) do
          find_field('default_card').click
        end
        expect(find_field('default_card')).to be_checked
      end

      expect(page).to have_content 'Default Card Updated'

      expect(default_card.reload.is_default).to be false
      within(".card#card#{default_card.id}") do
        expect(find_field('default_card')).to_not be_checked
      end
      expect(non_default_card.reload.is_default).to be true

      # Shows the interface for adding a card
      click_button 'Add a Card'
      expect(page).to have_field 'first_name'
      expect(page).to have_selector '#card-element.StripeElement'

      # Allows deletion of cards
      within(".card#card#{default_card.id}") do
        click_button 'Delete'
      end

      expect(page).to have_content(
        format("Your card has been removed (number: %s)", "x-#{default_card.last_digits}")
      )
      expect(page).to have_no_selector ".card#card#{default_card.id}"

      # Allows authorisation of card use by shops
      within "tr#customer#{customer.id}" do
        expect(find_field('allow_charges')).to_not be_checked
        find_field('allow_charges').click
      end
      expect(page).to have_content 'Changes saved.'
      expect(customer.reload.allow_charges).to be true
    end

    it "assign the default card to the next one when the default is deleted" do
      visit "/account"
      find("a", text: /Credit Cards/i).click

      within(".card#card#{default_card.id}") do
        click_button "Delete"
      end

      expect(page).to have_content "Your card has been removed"

      within ".card#card#{non_default_card.id}" do
        expect(find_field('default_card')).to be_checked
      end
      expect(non_default_card.reload.is_default).to be true
    end

    context "when no default card" do
      before do
        default_card.destroy
      end

      it "then all 'allow_charges' inputs are disabled" do
        visit "/account"
        find("a", text: /Credit Cards/i).click

        expect(find_field('allow_charges', disabled: true)).to be_truthy
      end
    end
  end
end
