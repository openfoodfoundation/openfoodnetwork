require 'spec_helper'

describe Spree::OrderUpdater do
  # Copied pretty much verbatim from Spree 2.4. Remove this file once we get there,
  # assuming the unchanged 2.4 logic still works for us.
  # Only changes are stubs of :empty? instead of :size
  context "updating payment state" do
    let(:order) { Spree::Order.new }
    let(:updater) { order.updater }

    it "is failed if no valid payments" do
      order.stub_chain(:payments, :valid, :empty?).and_return(true)

      updater.update_payment_state
      order.payment_state.should == 'failed'
    end

    context "payment total is greater than order total" do
      it "is credit_owed" do
        order.payment_total = 2
        order.total = 1

        expect {
          updater.update_payment_state
        }.to change { order.payment_state }.to 'credit_owed'
      end
    end

    context "order total is greater than payment total" do
      it "is credit_owed" do
        order.payment_total = 1
        order.total = 2

        expect {
          updater.update_payment_state
        }.to change { order.payment_state }.to 'balance_due'
      end
    end

    context "order total equals payment total" do
      it "is paid" do
        order.payment_total = 30
        order.total = 30

        expect {
          updater.update_payment_state
        }.to change { order.payment_state }.to 'paid'
      end
    end

    context "order is canceled" do
      before do
        order.state = 'canceled'
      end

      context "and is still unpaid" do
        it "is void" do
          order.payment_total = 0
          order.total = 30
          expect {
            updater.update_payment_state
          }.to change { order.payment_state }.to 'void'
        end
      end

      context "and is paid" do
        it "is credit_owed" do
          order.payment_total = 30
          order.total = 30
          order.stub_chain(:payments, :valid, :empty?).and_return(false)
          order.stub_chain(:payments, :completed, :empty?).and_return(false)
          expect {
            updater.update_payment_state
          }.to change { order.payment_state }.to 'credit_owed'
        end
      end

      context "and payment is refunded" do
        it "is void" do
          order.payment_total = 0
          order.total = 30
          order.stub_chain(:payments, :valid, :empty?).and_return(false)
          order.stub_chain(:payments, :completed, :empty?).and_return(false)
          expect {
            updater.update_payment_state
          }.to change { order.payment_state }.to 'void'
        end
      end
    end
  end
end
