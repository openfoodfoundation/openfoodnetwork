# frozen_string_literal: true

require 'spec_helper'

feature "Payments requiring action", js: true do
  include AuthenticationHelper

  describe "as a logged in user" do
    let(:user) { create(:user) }
    let(:order) { create(:order, user: user) }

    before do
      login_as user
    end

    context "there is a payment requiring authorization" do
      let!(:payment) do
        create(:payment,
               order: order,
               cvv_response_message: "https://stripe.com/redirect",
               state: "requires_authorization")
      end

      it "shows a table of payments requiring authorization" do
        visit "/account"

        find("a", text: /#{I18n.t('spree.users.show.tabs.transactions')}/i).click
        expect(page).to have_content I18n.t("spree.users.transactions.authorisation_required")
      end
    end

    context "there are no payments requiring authorization" do
      let!(:payment) do
        create(:payment, order: order, cvv_response_message: nil)
      end

      it "does not show the table of payments requiring authorization" do
        visit "/account"

        find("a", text: /#{I18n.t('spree.users.show.tabs.transactions')}/i).click
        expect(page).to_not have_content I18n.t("spree.users.transactions.authorisation_required")
      end
    end
  end
end
