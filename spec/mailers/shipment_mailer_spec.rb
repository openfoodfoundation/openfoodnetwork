# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Spree::ShipmentMailer do
  let(:order) { build(:order_with_distributor) }

  let(:shipment) do
    product = build(:product, name: %{The "BEST" product})
    variant = build(:variant, product:)
    line_item = build(:line_item, variant:, order:, quantity: 1, price: 5)
    shipment = build(:shipment)
    allow(shipment).to receive_messages(line_items: [line_item], order:)
    allow(shipment).to receive_messages(tracking_url: "TRACK_ME")
    shipment
  end

  let(:shipment_email) { described_class.shipped_email(shipment, delivery: true) }
  let(:picked_up_email) { described_class.shipped_email(shipment, delivery: false) }
  let(:distributor) { shipment.order.distributor }

  context ":from not set explicitly" do
    it "falls back to spree config" do
      expect(shipment_email.from).to eq [Spree::Config[:mails_from]]
    end
  end

  context "white labelling" do
    it_behaves_like 'email with inactive white labelling', :shipment_email
    it_behaves_like 'customer facing email with active white labelling', :shipment_email
    it_behaves_like 'email with inactive white labelling', :picked_up_email
    it_behaves_like 'customer facing email with active white labelling', :picked_up_email
  end

  # Regression test for #2196
  it "doesn't include out of stock in the email body" do
    expect(shipment_email.body).not_to include(%{Out of Stock})
  end

  it "shipment_email accepts an shipment id as an alternative to an Shipment object" do
    expect(Spree::Shipment).to receive(:find).with(shipment.id).and_return(shipment)
    expect {
      Spree::ShipmentMailer.shipped_email(shipment.id, delivery: true).deliver_now
    }.not_to raise_error
  end

  it "includes the distributor's name in the subject" do
    expect(shipment_email.subject).to include("#{distributor.name} Shipment Notification")
  end

  it "includes the distributor's name in the body" do
    expect(shipment_email.body).to include("Your order from #{distributor.name} has been shipped")
  end

  it "picked_up email includes different text in body" do
    text = "Your order from #{distributor.name} has been picked-up"
    expect(picked_up_email.body).to include(text)
  end

  it "picked_up email has different subject" do
    expect(picked_up_email.subject).to include("#{distributor.name} Pick up Notification")
  end

  it "picked_up email has as the reply to email as the distributor" do
    expect(picked_up_email.reply_to).to eq([distributor.contact.email])
  end

  it "shipment_email has as the reply to email as the distributor" do
    expect(shipment_email.reply_to).to eq([distributor.contact.email])
  end
end
