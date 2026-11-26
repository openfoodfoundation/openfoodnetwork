# frozen_string_literal: true

RSpec.describe PaypalRest::ItemsBuilderService do
  let(:order) { create(:completed_order_with_fees) }
  let(:items) { described_class.new(order).call }

  before { order.update_order! }

  it "lists line items with PayPal item fields" do
    line_item = order.line_items.first

    item = items.find { |i| i[:name] == line_item.product.name }

    expect(item).to include(
      sku: line_item.variant.sku,
      quantity: line_item.quantity.to_s,
      unit_amount: { currency_code: order.currency, value: format("%.2f", line_item.price) },
      category: PaypalServerSdk::ItemCategory::PHYSICAL_GOODS
    )
  end

  it "lists positive eligible adjustments as items" do
    adjustment = create(
      :adjustment, label: "Admin Adjustment", order:, adjustable: order,
                   amount: 12, originator: nil
    )
    order.update_order!

    item = items.find { |i| i[:name] == adjustment.label }

    expect(item).to include(
      quantity: "1",
      unit_amount: { currency_code: order.currency, value: "12.00" }
    )
  end

  it "excludes tax and shipping adjustments" do
    labels = order.all_adjustments.tax.or(order.all_adjustments.shipping).pluck(:label)

    expect(items.pluck(:name)).not_to include(*labels)
  end

  it "excludes ineligible adjustments" do
    adjustment = create(
      :adjustment, label: "Ineligible", order:, adjustable: order,
                   amount: 34, eligible: false
    )

    expect(items.pluck(:name)).not_to include(adjustment.label)
  end

  it "rejects items with a zero unit amount" do
    create(:line_item, order:, price: 0)
    order.update_order!

    expect(items.map { |i| i[:unit_amount][:value] }).not_to include("0.00")
  end

  describe "#discount_total" do
    it "sums negative eligible adjustments" do
      create(:adjustment, label: "Discount", order:, adjustable: order, amount: -5)
      create(:adjustment, label: "Ineligible discount", order:, adjustable: order,
                          amount: -9, eligible: false)

      expect(described_class.new(order).discount_total).to eq(5)
    end

    it "adds the customer's last credit payment without counting an adjustment twice" do
      credit_method = Spree::PaymentMethod.customer_credit
      create(:payment, order:, amount: 4, payment_method: credit_method, state: "checkout")
      order.payments.reset

      credit_adjustments = order.all_adjustments.where(originator: credit_method)
      expect(credit_adjustments.sum(:amount)).to eq(0)
      expect(described_class.new(order).discount_total).to eq(4)
    end
  end
end
