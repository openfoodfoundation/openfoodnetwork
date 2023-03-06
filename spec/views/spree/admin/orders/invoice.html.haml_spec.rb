# frozen_string_literal: true

require "spec_helper"

describe "spree/admin/orders/invoice.html.haml" do
  let(:shop) { create(:distributor_enterprise) }
  let(:order) { create(:completed_order_with_totals, distributor: shop) }
  let(:adas_address) do
    Spree::Address.new(
      firstname: "Ada",
      lastname: "Lovelace",
      phone: "0404 123 456",
      address1: "2 Mahome St",
      city: "Thornbury",
      zipcode: "3071",
      state_id: 1,
      state_name: "Victoria",
    )
  end
  let(:adas_address_display) { "2 Mahome St, Thornbury, 3071, Victoria" }

  before do
    assign(:order, order)
    allow(view).to receive_messages checkout_adjustments_for: [],
                                    display_line_items_taxes: '',
                                    display_checkout_tax_total: '10',
                                    display_checkout_total_less_tax: '8',
                                    outstanding_balance_label: 'Outstanding Balance'

    stub_request(:get, ->(uri) { uri.to_s.include? "/css/mail" })
  end

  it "displays the customer code" do
    order.customer = Customer.create!(
      user: order.user,
      email: order.user.email,
      enterprise: order.distributor,
      code: "Money Penny",
    )
    render
    expect(rendered).to have_content "Code: Money Penny"
  end

  it "displays the billing address" do
    order.bill_address = adas_address
    render
    expect(rendered).to have_content "Ada Lovelace"
    expect(rendered).to have_content adas_address.phone
    expect(rendered).to have_content adas_address_display
  end

  it "displays shipping info" do
    order.shipping_method.update!(
      name: "Home delivery",
      require_ship_address: true,
    )
    order.ship_address = adas_address

    render
    expect(rendered).to have_content "Shipping: Home delivery"
    expect(rendered).to have_content adas_address.phone
    expect(rendered).to have_content adas_address_display
  end

  it "displays special instructions" do
    order.special_instructions = "The combination is 12345."

    render
    expect(rendered).to have_content "The combination is 12345."
  end

  it "hides billing address for pickups" do
    order.ship_address = adas_address
    order.shipping_method.update!(
      name: "Pickup",
      require_ship_address: false,
    )

    render
    expect(rendered).to have_content "Shipping: Pickup"
    expect(rendered).to_not have_content adas_address_display
  end

  it "displays order note on invoice when note is given" do
    order.note = "Test note"

    render
    expect(rendered).to have_content "Test note"
  end
end
