# frozen_string_literal: true

require "spec_helper"

describe "checkout/_voucher_section.html.haml" do
  let(:order) { create(:order_with_distributor, total: 10) }
  let(:flat_voucher) {
    create(:voucher_flat_rate, code: "flat_code",
                               enterprise: order.distributor, amount: 20)
  }
  let(:percent_voucher) {
    create(:voucher_percentage_rate, code: 'percent_code',
                                     enterprise: order.distributor, amount: 20)
  }
  let(:note) {
    ["Note: if your order total is less than your voucher",
     "you may not be able to spend the remaining value."].join(" ")
  }

  it "should display warning_forfeit_remaining_amount note" do
    add_voucher(flat_voucher, order)

    allow(view).to receive_messages(
      order:,
      voucher_adjustment: order.voucher_adjustments.first
    )
    assign(:order, order)

    render
    expect(rendered).to have_content(note)
  end

  it "should not display warning_forfeit_remaining_amount note" do
    add_voucher(percent_voucher, order)

    allow(view).to receive_messages(
      order:,
      voucher_adjustment: order.voucher_adjustments.first
    )
    assign(:order, order)

    render
    expect(rendered).to_not have_content(note)
  end

  def add_voucher(voucher, order)
    voucher.create_adjustment(voucher.code, order)
    order.update_order!

    VoucherAdjustmentsService.new(order).update
  end
end
