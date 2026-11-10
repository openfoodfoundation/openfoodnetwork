# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Payments by payment type", swagger_doc: "v1.yaml" do
  let!(:distributor) { create(:distributor_enterprise) }
  let!(:other_distributor) { create(:distributor_enterprise) }
  let!(:coordinator) { create(:distributor_enterprise) }

  let!(:order_cycle) do
    create(:simple_order_cycle, coordinator:)
  end

  let!(:other_order_cycle) do
    create(:simple_order_cycle, coordinator:)
  end

  let!(:order) do
    create(:completed_order_with_totals, distributor:, order_cycle:)
  end

  let!(:other_hub_order) do
    create(
      :completed_order_with_totals,
      distributor: other_distributor,
      order_cycle:
    )
  end

  let!(:other_cycle_order) do
    create(
      :completed_order_with_totals,
      distributor:,
      order_cycle: other_order_cycle
    )
  end

  let!(:bank_method) do
    create(
      :payment_method,
      name: "Bank transfer",
      distributors: [distributor, other_distributor]
    )
  end

  let!(:card_method) do
    create(
      :payment_method,
      name: "Card",
      distributors: [distributor]
    )
  end

  before do
    order.finalize!
    other_hub_order.finalize!
    other_cycle_order.finalize!

    create(
      :payment, :completed,
      order:,
      payment_method: bank_method,
      amount: 7
    )
    create(
      :payment, :completed,
      order:,
      payment_method: card_method,
      amount: 3
    )
    create(
      :payment,
      order:,
      payment_method: bank_method,
      state: "checkout",
      amount: 99
    )
    create(
      :payment, :completed,
      order: other_cycle_order,
      payment_method: bank_method,
      amount: 11
    )
    create(
      :payment, :completed,
      order: other_hub_order,
      payment_method: bank_method,
      amount: 13
    )

    login_as distributor.owner
  end

  def totals_by_hub_and_payment_type
    json_response[:data].
      group_by { |row| [row[:distributor], row[:payment_type]] }.
      transform_values do |rows|
        rows.sum { |row| BigDecimal(row[:total_price].to_s) }
      end
  end

  it "defaults to payment types and includes only completed payments" do
    get "/api/v1/reports/payments", params: {
      order_cycle_id: order_cycle.id,
      distributor_id: distributor.id
    }

    expect(response).to have_http_status(:ok)
    expect(totals_by_hub_and_payment_type).to eq(
      [distributor.name, bank_method.name] => 7,
      [distributor.name, card_method.name] => 3
    )
  end

  it "supports the explicit payment-type subtype" do
    get "/api/v1/reports/payments", params: {
      report_subtype: "payments_by_payment_type",
      order_cycle_id: order_cycle.id,
      distributor_id: distributor.id
    }

    expect(response).to have_http_status(:ok)
    expect(totals_by_hub_and_payment_type).to eq(
      [distributor.name, bank_method.name] => 7,
      [distributor.name, card_method.name] => 3
    )
  end

  it "filters by order cycle across managed hubs" do
    EnterpriseRole.create!(
      user: distributor.owner,
      enterprise: other_distributor
    )

    get "/api/v1/reports/payments",
        params: { order_cycle_id: order_cycle.id }

    expect(response).to have_http_status(:ok)
    expect(totals_by_hub_and_payment_type).to eq(
      [distributor.name, bank_method.name] => 7,
      [distributor.name, card_method.name] => 3,
      [other_distributor.name, bank_method.name] => 13
    )
  end

  it "filters by distributor across order cycles" do
    EnterpriseRole.create!(
      user: distributor.owner,
      enterprise: other_distributor
    )

    get "/api/v1/reports/payments",
        params: { distributor_id: distributor.id }

    expect(response).to have_http_status(:ok)
    expect(totals_by_hub_and_payment_type).to eq(
      [distributor.name, bank_method.name] => 18,
      [distributor.name, card_method.name] => 3
    )
  end

  it "excludes payments from an unmanaged hub" do
    get "/api/v1/reports/payments",
        params: { order_cycle_id: order_cycle.id }

    expect(response).to have_http_status(:ok)
    expect(totals_by_hub_and_payment_type).to eq(
      [distributor.name, bank_method.name] => 7,
      [distributor.name, card_method.name] => 3
    )
  end
end
