# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ReportsHelper do
  describe "#report_payment_method_options" do
    let(:order_with_payments) { create(:order_ready_to_ship) }
    let(:order_without_payments) { create(:order_with_line_items) }
    let(:orders) { [order_with_payments, order_without_payments] }
    let(:payment_method) { order_with_payments.payments.last.payment_method }

    it "returns payment method select options for given orders" do
      select_options = helper.report_payment_method_options([order_with_payments])

      expect(select_options).to eq [[payment_method.name, payment_method.id]]
    end

    it "handles orders that don't have payments, without error" do
      select_options = helper.report_payment_method_options(orders)

      expect(select_options).to eq [[payment_method.name, payment_method.id]]
    end
  end

  describe "#prices_sum" do
    it "sums to prices list roundind to 2 decimals" do
      expect(helper.prices_sum([1, nil, 2.333333, 1.5, 2.0])).to eq(6.83)
    end
  end
end
