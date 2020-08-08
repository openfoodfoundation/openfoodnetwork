# frozen_string_literal: true

require 'spec_helper'

describe Spree::Order do
  let(:order) { Spree::Order.new }
  before do
    # Ensure state machine has been re-defined correctly
    Spree::Order.define_state_machine!
    # We don't care about this validation here
    order.stub(:require_email)
  end

  context "#next!" do
    context "when current state is payment" do
      before do
        order.state = "payment"
        order.run_callbacks(:create)
        order.stub payment_required?: true
        order.stub process_payments!: true
        order.stub :has_available_shipment
      end

      context "when payment processing succeeds" do
        before { order.stub process_payments!: true }

        it "should finalize order when transitioning to complete state" do
          order.should_receive(:finalize!)
          order.next!
        end

        context "when credit card processing fails" do
          before { order.stub process_payments!: false }

          it "should not complete the order" do
            order.next
            expect(order.state).to eq "payment"
          end
        end
      end

      context "when payment processing fails" do
        before { order.stub process_payments!: false }

        it "cannot transition to complete" do
          order.next
          expect(order.state).to eq "payment"
        end
      end
    end

    context "when current state is address" do
      before do
        order.stub(:has_available_payment)
        order.stub(:ensure_available_shipping_rates)
        order.state = "address"
      end

      it "adjusts tax rates when transitioning to delivery" do
        # Once because the record is being saved
        # Twice because it is transitioning to the delivery state
        Spree::TaxRate.should_receive(:adjust).twice
        order.next!
      end
    end

    context "when current state is delivery" do
      before do
        order.state = "delivery"
        order.stub total: 10.0
      end
    end
  end

  context "#can_cancel?" do
    %w(pending backorder ready).each do |shipment_state|
      it "should be true if shipment_state is #{shipment_state}" do
        order.stub completed?: true
        order.shipment_state = shipment_state
        expect(order.can_cancel?).to be_truthy
      end
    end

    (Spree::Shipment.state_machine.states.keys - %w(pending backorder ready)).each do |shipment_state|
      it "should be false if shipment_state is #{shipment_state}" do
        order.stub completed?: true
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
      shipment.stub inventory_units: inventory_units
      order.stub shipments: [shipment]
      shipment
    end

    before do
      order.stub line_items: [build(:line_item, variant: variant, quantity: 2)]
      order.line_items.stub find_by_variant_id: order.line_items.first

      order.stub completed?: true
      order.stub allow_cancel?: true
    end

    it "should send a cancel email" do
      # Stub methods that cause side-effects in this test
      shipment.stub(:cancel!)
      order.stub :has_available_shipment
      order.stub :restock_items!
      mail_message = double "Mail::Message"
      order_id = nil
      Spree::OrderMailer.should_receive(:cancel_email) { |*args|
        order_id = args[0]
        mail_message
      }
      mail_message.should_receive :deliver
      order.cancel!
      expect(order_id).to eq order.id
    end

    context "restocking inventory" do
      before do
        shipment.stub(:ensure_correct_adjustment)
        shipment.stub(:update_order)
        Spree::OrderMailer.stub(:cancel_email).and_return(mail_message = double)
        mail_message.stub :deliver

        order.stub :has_available_shipment
      end
    end

    context "resets payment state" do
      before do
        # Stubs methods that cause unwanted side effects in this test
        Spree::OrderMailer.stub(:cancel_email).and_return(mail_message = double)
        mail_message.stub :deliver
        order.stub :has_available_shipment
        order.stub :restock_items!
        shipment.stub(:cancel!)
      end

      context "without shipped items" do
        it "should set payment state to 'credit owed'" do
          order.cancel!
          expect(order.payment_state).to eq 'credit_owed'
        end
      end

      context "with shipped items" do
        before do
          order.stub shipment_state: 'partial'
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
      order.stub email: "user@spreecommerce.com"
      order.stub state: "canceled"
      order.stub allow_resume?: true

      # Stubs method that cause unwanted side effects in this test
      order.stub :has_available_shipment
    end
  end
end
