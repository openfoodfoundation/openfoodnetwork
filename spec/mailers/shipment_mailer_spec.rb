# frozen_string_literal: true

require 'spec_helper'

describe Spree::ShipmentMailer do
  let(:shipment) do
    order = build(:order)
    product = build(:product, name: %{The "BEST" product})
    variant = build(:variant, product: product)
    line_item = build(:line_item, variant: variant, order: order, quantity: 1, price: 5)
    shipment = build(:shipment)
    allow(shipment).to receive_messages(line_items: [line_item], order: order)
    allow(shipment).to receive_messages(tracking_url: "TRACK_ME")
    shipment
  end

  context ":from not set explicitly" do
    it "falls back to spree config" do
      message = Spree::ShipmentMailer.shipped_email(shipment)
      expect(message.from).to eq [Spree::Config[:mails_from]]
    end
  end

  # Regression test for #2196
  it "doesn't include out of stock in the email body" do
    shipment_email = Spree::ShipmentMailer.shipped_email(shipment)
    expect(shipment_email.body).to_not include(%{Out of Stock})
  end

  it "shipment_email accepts an shipment id as an alternative to an Shipment object" do
    expect(Spree::Shipment).to receive(:find).with(shipment.id).and_return(shipment)
    expect {
      Spree::ShipmentMailer.shipped_email(shipment.id).deliver
    }.to_not raise_error
  end
end
