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

  it "displays the billing and shipping address" do
    order.bill_address = adas_address
    render
    expect(rendered).to have_content "To: Ada Lovelace"
    expect(rendered).to have_content adas_address.phone
    expect(rendered).to have_content adas_address_display
  end

  it "displays shipping info" do
    order.shipping_method.update_attributes!(
      name: "Home delivery",
      require_ship_address: true,
    )
    order.ship_address = adas_address

    render
    expect(rendered).to have_content "Shipping: Home delivery"
    expect(rendered).to have_content adas_address_display
  end

  it "prints address once if billing and shipping address are the same" do
    order.bill_address = adas_address
    order.ship_address = Spree::Address.new(order.bill_address.attributes)
    order.shipping_method.update_attributes!(
      name: "Home delivery",
      require_ship_address: true,
    )

    render
    expect(rendered).to have_content "Shipping: Home delivery"
    expect(rendered.scan(/2 Mahome St, Thornbury, 3071/).count).to eq 1
  end
end
