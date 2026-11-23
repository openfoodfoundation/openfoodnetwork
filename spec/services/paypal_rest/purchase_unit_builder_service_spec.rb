# frozen_string_literal: true

RSpec.describe PaypalRest::PurchaseUnitBuilderService do
  let(:order) { create(:completed_order_with_fees) }
  let(:payment) { order.payments.first }

  before { order.update_order! }

  it "uses the order number and payment id as the invoice id" do
    payload = described_class.new(order:, payment:).call

    expect(payload[:invoice_id]).to eq("#{order.number}-#{payment.id}")
  end

  it "uses the payment amount when one is given" do
    payload = described_class.new(order:, payment:).call

    expect(payload[:amount]).to include(
      currency_code: order.currency, value: format("%.2f", payment.amount)
    )
  end

  it "falls back to the order total without a payment" do
    payload = described_class.new(order:, payment: nil).call

    expect(payload[:invoice_id]).to eq(order.number)
    expect(payload[:amount][:value]).to eq(format("%.2f", order.total))
  end

  it "includes an itemized breakdown with tax, shipping and discounts" do
    create(:adjustment, label: "Discount", order:, adjustable: order, amount: -2)
    order.update_order!

    breakdown = described_class.new(order:, payment:).call[:amount][:breakdown]
    items = PaypalRest::ItemsBuilderService.new(order).call
    expected_item_total = items.sum do |item|
      item[:quantity].to_i * item[:unit_amount][:value].to_d
    end

    expect(breakdown[:item_total][:value]).to eq(format("%.2f", expected_item_total))
    expect(breakdown[:shipping][:value]).to eq(format("%.2f", order.ship_total))
    expect(breakdown[:tax_total][:value]).to eq(
      format("%.2f", order.all_adjustments.tax.additional.sum(:amount))
    )
    expect(breakdown[:discount][:value]).to eq("2.00")
  end

  it "has a breakdown that adds up to the total amount" do
    payload = described_class.new(order:, payment:).call
    breakdown = payload[:amount][:breakdown]
    discount = breakdown.fetch(:discount, { value: '0' })[:value].to_d

    total = breakdown[:item_total][:value].to_d + breakdown[:shipping][:value].to_d +
            breakdown[:tax_total][:value].to_d - discount

    expect(total).to eq(payload[:amount][:value].to_d)
  end

  it "omits the breakdown and items when there are no positive items" do
    empty_order = create(:order_with_distributor)

    payload = described_class.new(order: empty_order, payment: nil).call

    expect(payload[:amount]).not_to have_key(:breakdown)
    expect(payload).not_to have_key(:items)
  end

  describe "shipping details" do
    it "includes the shipping address when it is required" do
      payload = described_class.new(order:, payment:, address_required: true).call
      address = order.ship_address

      expect(payload[:shipping]).to eq(
        name: { full_name: address.full_name },
        address: {
          "address_line_1" => address.address1,
          "address_line_2" => address.address2,
          "admin_area_2" => address.city,
          "admin_area_1" => address.state_text,
          "postal_code" => address.zipcode,
          "country_code" => address.country&.iso
        }.compact
      )
    end

    it "omits shipping details when they are not required" do
      payload = described_class.new(order:, payment:, address_required: false).call

      expect(payload).not_to have_key(:shipping)
    end
  end
end
