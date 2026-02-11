# frozen_string_literal: true

require 'system_helper'

RSpec.describe "Admin -> Order -> Payments" do
  include AuthenticationHelper
  include TableHelper

  let(:distributor) { build(:distributor_enterprise) }
  let(:order) { create(:completed_order_with_fees, distributor:, payments: [payment]) }
  let(:payment) {
    build(:payment, :completed, payment_method: taler, source: taler, response_code: "taler-id-1")
  }
  let(:taler) {
    Spree::PaymentMethod::Taler.new(
      name: "Taler",
      distributors: [distributor],
      environment: "test",
      preferred_backend_url: "https://taler.example.com",
      preferred_api_key: "sandbox",
    )
  }

  before do
    login_as distributor.owner
  end

  it "allows to refund a Taler payment" do
    order_status = {
      order_status: "paid",
      contract_terms: {
        amount: "KUDOS:2",
      }
    }
    order_endpoint = "https://taler.example.com/private/orders/taler-id-1"
    refund_endpoint = "https://taler.example.com/private/orders/taler-id-1/refund"
    stub_request(:get, order_endpoint).to_return(body: order_status.to_json)
    stub_request(:post, refund_endpoint).to_return(body: "{}")

    visit spree.admin_order_payments_path(order.number)

    within row_containing("Taler") do
      expect(page).to have_text "COMPLETED"
      expect(page).to have_link class: "icon-void"

      click_link class: "icon-void"

      expect(page).to have_text "VOID"
      expect(page).not_to have_link class: "icon-void"
    end
  end
end
