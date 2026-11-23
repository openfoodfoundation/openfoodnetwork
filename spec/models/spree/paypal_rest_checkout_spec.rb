# frozen_string_literal: true

RSpec.describe Spree::PaypalRestCheckout do
  it "stores the PayPal order, capture, payer and refund identifiers" do
    refunded_at = Time.zone.now

    source = described_class.create!(
      order_id: 'ORDER-1',
      capture_id: 'CAPTURE-1',
      payer_id: 'PAYER-1',
      status: 'COMPLETED',
      refund_id: 'REFUND-1',
      refunded_at:
    )

    expect(source.reload).to have_attributes(
      order_id: 'ORDER-1',
      capture_id: 'CAPTURE-1',
      payer_id: 'PAYER-1',
      status: 'COMPLETED',
      refund_id: 'REFUND-1'
    )
    expect(source.refunded_at).to be_within(1.second).of(refunded_at)
  end

  it "requires a PayPal order ID" do
    expect { described_class.create!(order_id: nil) }.to raise_error(ActiveRecord::NotNullViolation)
  end
end
