# frozen_string_literal: true

require "system_helper"

RSpec.describe "Bulk crediting orders" do
  include AuthenticationHelper

  let(:distributor) { create(:distributor_enterprise) }
  let!(:order) { create(:completed_order_with_fees, distributor:) }
  let!(:order_without_customer) { create(:completed_order_with_fees, distributor:) }

  before do
    [order, order_without_customer].each do |overpaid_order|
      payment = overpaid_order.payments.first
      payment.complete!
      payment.update!(amount: 48.00)
      overpaid_order.update_order!
    end
    order_without_customer.update_column(:customer_id, nil)

    login_as distributor.owner
    visit spree.admin_orders_path
  end

  it "reports the missing customer and credits only the valid order in a mixed selection" do
    payments = order_without_customer.payments.reload.pluck(:id, :amount, :state)
    transaction_count = CustomerAccountTransaction.count

    [order, order_without_customer].each do |selected_order|
      find("input[name='bulk_ids[]'][value='#{selected_order.id}']").click
    end
    find("span.icon-reorder", text: "Actions").click
    within ".ofn-drop-down .menu" do
      find("span", text: "Credit orders").click
    end

    expect(page).to have_content(
      "Order ##{order_without_customer.number} could not be credited : " \
      "No customer is assigned to this order"
    )
    within "#order_#{order.id}" do
      expect(page).to have_css(".state.paid", text: /paid/i)
    end

    expect(order.reload.payment_state).to eq("paid")
    expect(order.customer.customer_account_transactions.last.amount).to eq(12.00)
    expect(CustomerAccountTransaction.count).to eq(transaction_count + 1)
    expect(order_without_customer.reload.payment_state).to eq("credit_owed")
    expect(order_without_customer.new_outstanding_balance).to eq(-12.00)
    expect(order_without_customer.payments.pluck(:id, :amount, :state)).to eq(payments)
  end
end
