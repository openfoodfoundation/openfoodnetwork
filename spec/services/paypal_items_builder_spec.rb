# frozen_string_literal: true

require 'spec_helper'

describe PaypalItemsBuilder do
  let(:order) { create(:completed_order_with_fees) }
  let(:service) { described_class.new(order) }
  let(:items) { described_class.new(order).call }

  it "lists line items" do
    line_item = order.line_items.first

    expect(items.first[:Name]).to eq line_item.variant.name
    expect(items.first[:Number]).to eq line_item.variant.sku
    expect(items.first[:Quantity]).to eq line_item.quantity
    expect(items.first[:Amount]).to eq(currencyID: order.currency,
                                       value: line_item.price)
    expect(items.first[:ItemCategory]).to eq "Physical"
  end

  context "listing adjustments" do
    let!(:admin_adjustment) {
      create(:adjustment, label: "Admin Adjustment", order: order, adjustable: order,
                          amount: 12, originator: nil, state: "closed")
    }
    let!(:ineligible_adjustment) {
      create(:adjustment, label: "Ineligible Adjustment", order: order, adjustable: order,
                          amount: 34, eligible: false, state: "closed",
                          originator_type: "Spree::PaymentMethod")
    }
    let!(:zone) { create(:zone_with_member) }
    let!(:included_tax_rate) {
      create(:tax_rate, amount: 12, included_in_price: true, zone: zone,
                        calculator: ::Calculator::DefaultTax.new)
    }
    let!(:additional_tax_rate) {
      create(:tax_rate, amount: 34, included_in_price: false, zone: zone,
                        calculator: ::Calculator::DefaultTax.new)
    }
    let!(:included_tax_adjustment) {
      create(:adjustment, label: "Included Tax Adjustment", order: order,
                          adjustable: order.line_items.first, amount: 56,
                          originator: included_tax_rate, included: true, state: "closed")
    }
    let!(:additional_tax_adjustment) {
      create(:adjustment, label: "Additional Tax Adjustment", order: order,
                          adjustable: order.shipment, amount: 78, originator: additional_tax_rate,
                          state: "closed")
    }
    let!(:enterprise_fee) { create(:enterprise_fee) }
    let!(:line_item_enterprise_fee) {
      create(:adjustment, label: "Line Item Fee", order: order, adjustable: order.line_items.first,
                          amount: 91, originator: enterprise_fee, state: "closed")
    }
    let!(:order_enterprise_fee) {
      create(:adjustment, label: "Order Fee", order: order, adjustable: order,
                          amount: 23, originator: enterprise_fee, state: "closed")
    }

    before { order.update_order! }

    it "should add up to the order total, minus any additional tax and the shipping cost" do
      items_total = items.sum { |i| i[:Quantity] * i[:Amount][:value] }
      order_tax_total = order.all_adjustments.tax.additional.sum(:amount)

      expect(items_total).to eq(order.total - order_tax_total - order.ship_total)
    end

    it "lists the payment fee adjustment" do
      payment_fee = items.find{ |i| i[:Name] == 'Transaction fee' }

      expect(payment_fee[:Quantity]).to eq 1
      expect(payment_fee[:Amount]).to eq(currencyID: order.currency,
                                         value: order.all_adjustments.payment_fee.first.amount)
    end

    it "lists admin adjustments" do
      admin_item = items.find{ |i| i[:Name] == admin_adjustment.label }

      expect(order.all_adjustments.admin.count).to eq 1
      expect(admin_item[:Quantity]).to eq 1
      expect(admin_item[:Amount]).to eq(currencyID: order.currency,
                                        value: order.all_adjustments.admin.first.amount)
    end

    it "lists enterprise fee adjustments" do
      line_item_fee = items.find{ |i| i[:Name] == line_item_enterprise_fee.label }
      order_fee = items.find{ |i| i[:Name] == order_enterprise_fee.label }

      expect(order.all_adjustments.enterprise_fee.count).to eq 2

      expect(line_item_fee[:Quantity]).to eq 1
      expect(line_item_fee[:Amount]).to eq(currencyID: order.currency,
                                           value: line_item_enterprise_fee.amount)
      expect(order_fee[:Quantity]).to eq 1
      expect(order_fee[:Amount]).to eq(currencyID: order.currency,
                                       value: order_enterprise_fee.amount)
    end

    it "does not list tax adjustments" do
      tax_adjustment_items = items.select do |i|
        i[:Name].in? [additional_tax_adjustment.label, included_tax_adjustment.label]
      end

      expect(order.all_adjustments.tax.inclusive.count).to eq 1
      expect(order.all_adjustments.tax.additional.count).to eq 1
      expect(tax_adjustment_items.count).to be_zero
    end

    it "does not list the shipping fee" do
      shipping_fee_item = items.find{ |i| i[:Name] == 'Shipping' }

      expect(order.all_adjustments.shipping.count).to eq 1
      expect(shipping_fee_item).to be_nil
    end

    it "does not list ineligible adjustments" do
      ineligible_item = items.detect{ |i| i[:Name] == ineligible_adjustment.label }

      expect(order.adjustments.where(eligible: false).count).to eq 1
      expect(ineligible_item).to be_nil
    end
  end
end
