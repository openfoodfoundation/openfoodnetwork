# frozen_string_literal: true

RSpec.describe "spree/users/_customer_account_transactions.html.haml" do
  helper EnterprisesHelper

  let(:user) { create(:user) }
  let(:shop) { create(:distributor_enterprise) }
  let(:customer) { create(:customer, enterprise: shop, user:) }

  before do
    assign(:user, user)
    assign(:shops, [shop])
  end

  context "when the customer has credit" do
    before { create(:customer_account_transaction, customer:, amount: 1.00) }

    it "shows the credit available" do
      render

      expect(rendered).to have_content("Credit available: $1.00")
    end
  end

  context "when a balance has been carried over to the customer's next order" do
    before { create(:customer_account_transaction, customer:, amount: -0.57) }

    it "shows the balance due rather than a negative credit" do
      render

      expect(rendered).to have_content("Balance due: $0.57")
      expect(rendered).not_to have_content("Credit available")
    end
  end
end
