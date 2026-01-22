# frozen_string_literal: true

RSpec.describe Spree::ShipmentMailer do
  let(:shipment) do
    order = build(:order_with_distributor)
    product = build(:product, name: %{The "BEST" product})
    variant = build(:variant, product:)
    line_item = build(:line_item, variant:, order:, quantity: 1, price: 5)
    shipment = build(:shipment)
    allow(shipment).to receive_messages(line_items: [line_item], order:)
    allow(shipment).to receive_messages(tracking_url: "TRACK_ME")
    shipment
  end
  let(:distributor) { shipment.order.distributor }

  context ":from not set explicitly" do
    it "falls back to spree config" do
      message = Spree::ShipmentMailer.shipped_email(shipment, delivery: true)
      expect(message.from).to eq [Spree::Config[:mails_from]]
    end
  end

  # Regression test for #2196
  it "doesn't include out of stock in the email body" do
    shipment_email = Spree::ShipmentMailer.shipped_email(shipment, delivery: true)
    expect(shipment_email.body).not_to include(%{Out of Stock})
  end

  it "shipment_email accepts an shipment id as an alternative to an Shipment object" do
    expect(Spree::Shipment).to receive(:find).with(shipment.id).and_return(shipment)
    expect {
      Spree::ShipmentMailer.shipped_email(shipment.id, delivery: true).deliver_now
    }.not_to raise_error
  end

  it "includes the distributor's name in the subject" do
    shipment_email = Spree::ShipmentMailer.shipped_email(shipment, delivery: true)
    expect(shipment_email.subject).to include("#{distributor.name} Shipment Notification")
  end

  it "includes the distributor's name in the body" do
    shipment_email = Spree::ShipmentMailer.shipped_email(shipment, delivery: true)
    expect(shipment_email.body).to include("Your order from #{distributor.name} has been shipped")
  end

  it "picked_up email includes different text in body" do
    text = "Your order from #{distributor.name} has been picked-up"
    picked_up_email = Spree::ShipmentMailer.shipped_email(shipment, delivery: false)
    expect(picked_up_email.body).to include(text)
  end

  it "picked_up email has different subject" do
    shipment_email = Spree::ShipmentMailer.shipped_email(shipment, delivery: false)
    expect(shipment_email.subject).to include("#{distributor.name} Pick up Notification")
  end

  it "picked_up email has as the reply to email as the distributor" do
    shipment_email = Spree::ShipmentMailer.shipped_email(shipment, delivery: false)
    expect(shipment_email.reply_to).to eq([distributor.contact.email])
  end

  it "shipment_email email has as the reply to email as the distributor" do
    shipment_email = Spree::ShipmentMailer.shipped_email(shipment, delivery: true)
    expect(shipment_email.reply_to).to eq([distributor.contact.email])
  end
end
