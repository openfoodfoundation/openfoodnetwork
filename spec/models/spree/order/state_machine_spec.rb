# frozen_string_literal: true

require 'spec_helper'

describe Spree::Order do
  let(:order) { Spree::Order.new }
  before do
    # Ensure state machine has been re-defined correctly
    Spree::Order.define_state_machine!
    # We don't care about this validation here
    allow(order).to receive(:require_email)
  end

  context "#next!" do
    context "when current state is payment" do
      before do
        order.state = "payment"
        order.run_callbacks(:create)
        allow(order).to receive_messages payment_required?: true
        allow(order).to receive_messages process_payments!: true
        allow(order).to receive :has_available_shipment
      end

      context "when payment processing succeeds" do
        before { allow(order).to receive_messages process_payments!: true }

        it "should finalize order when transitioning to complete state" do
          expect(order).to receive(:finalize!)
          order.next!
        end

        context "when credit card processing fails" do
          before { allow(order).to receive_messages process_payments!: false }

          it "should not complete the order" do
            order.next
            expect(order.state).to eq "payment"
          end
        end
      end

      context "when payment processing fails" do
        before { allow(order).to receive_messages process_payments!: false }

        it "cannot transition to complete" do
          order.next
          expect(order.state).to eq "payment"
        end
      end
    end

    context "when current state is address" do
      before do
        allow(order).to receive(:has_available_payment)
        allow(order).to receive(:ensure_available_shipping_rates)
        order.state = "address"
      end

      it "adjusts tax rates when transitioning to delivery" do
        # Once because the record is being saved
        # Twice because it is transitioning to the delivery state
        expect(Spree::TaxRate).to receive(:adjust).twice
        order.next!
      end
    end

    context "when current state is delivery" do
      before do
        order.state = "delivery"
        allow(order).to receive_messages total: 10.0
      end
    end
  end

  context "#can_cancel?" do
    %w(pending backorder ready).each do |shipment_state|
      it "should be true if shipment_state is #{shipment_state}" do
        allow(order).to receive_messages completed?: true
        order.shipment_state = shipment_state
        expect(order.can_cancel?).to be_truthy
      end
    end

    (Spree::Shipment.state_machine.states.keys - %w(pending backorder ready)).each do |shipment_state|
      it "should be false if shipment_state is #{shipment_state}" do
        allow(order).to receive_messages completed?: true
        order.shipment_state = shipment_state
        expect(order.can_cancel?).to be_falsy
      end
    end
  end

  context "#cancel" do
    let!(:variant) { build(:variant) }
    let!(:inventory_units) {
      [build(:inventory_unit, variant: variant),
       build(:inventory_unit, variant: variant)]
    }
    let!(:shipment) do
      shipment = build(:shipment)
      allow(shipment).to receive_messages inventory_units: inventory_units
      allow(order).to receive_messages shipments: [shipment]
      shipment
    end

    before do
      allow(order).to receive_messages line_items: [build(:line_item, variant: variant, quantity: 2)]
      allow(order.line_items).to receive_messages find_by_variant_id: order.line_items.first

      allow(order).to receive_messages completed?: true
      allow(order).to receive_messages allow_cancel?: true
    end

    it "should send a cancel email" do
      # Stub methods that cause side-effects in this test
      allow(shipment).to receive(:cancel!)
      allow(order).to receive :has_available_shipment
      allow(order).to receive :restock_items!
      mail_message = double "Mail::Message"
      order_id = nil
      expect(Spree::OrderMailer).to receive(:cancel_email) { |*args|
        order_id = args[0]
        mail_message
      }
      expect(mail_message).to receive :deliver
      order.cancel!
      expect(order_id).to eq order.id
    end

    context "restocking inventory" do
      before do
        allow(shipment).to receive(:ensure_correct_adjustment)
        allow(shipment).to receive(:update_order)
        allow(Spree::OrderMailer).to receive(:cancel_email).and_return(mail_message = double)
        allow(mail_message).to receive :deliver

        allow(order).to receive :has_available_shipment
      end
    end

    context "resets payment state" do
      before do
        # Stubs methods that cause unwanted side effects in this test
        allow(Spree::OrderMailer).to receive(:cancel_email).and_return(mail_message = double)
        allow(mail_message).to receive :deliver
        allow(order).to receive :has_available_shipment
        allow(order).to receive :restock_items!
        allow(shipment).to receive(:cancel!)
      end

      context "without shipped items" do
        it "should set payment state to 'credit owed'" do
          order.cancel!
          expect(order.payment_state).to eq 'credit_owed'
        end
      end

      context "with shipped items" do
        before do
          allow(order).to receive_messages shipment_state: 'partial'
        end

        it "should not alter the payment state" do
          order.cancel!
          expect(order.payment_state).to be_nil
        end
      end
    end
  end

  # Another regression test for Spree #729
  context "#resume" do
    before do
      allow(order).to receive_messages email: "user@spreecommerce.com"
      allow(order).to receive_messages state: "canceled"
      allow(order).to receive_messages allow_resume?: true

      # Stubs method that cause unwanted side effects in this test
      allow(order).to receive :has_available_shipment
    end
  end
end
