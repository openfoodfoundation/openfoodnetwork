# frozen_string_literal: true

require 'system_helper'

RSpec.describe "Payments requiring action" do
  include AuthenticationHelper

  describe "as a logged in user" do
    let(:user) { create(:user) }
    let(:order) { create(:order, user:) }

    before do
      login_as user
    end

    context "there is a payment requiring authorization" do
      let!(:payment) do
        create(:payment,
               order:,
               redirect_auth_url: "https://stripe.com/redirect",
               state: "requires_authorization")
      end

      it "shows a table of payments requiring authorization" do
        visit "/account"

        find("a", text: /Transactions/i).click
        expect(page).to have_content 'Authorisation Required'
      end
    end

    context "there are no payments requiring authorization" do
      let!(:payment) do
        create(:payment, order:, redirect_auth_url: nil)
      end

      it "does not show the table of payments requiring authorization" do
        visit "/account"

        find("a", text: /Transactions/i).click
        expect(page).not_to have_content 'Authorisation Required'
      end
    end
  end
end
