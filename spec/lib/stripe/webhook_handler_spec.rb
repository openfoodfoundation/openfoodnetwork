# frozen_string_literal: true

require 'spec_helper'
require 'stripe/webhook_handler'

module Stripe
  describe WebhookHandler do
    let(:event) { double(:event, type: 'some.event') }
    let(:handler) { WebhookHandler.new(event) }

    describe "event_mappings" do
      it { expect(handler.send(:event_mappings)).to be_a Hash }
    end

    describe "known_event?" do
      context "when event mappings know about the event type" do
        before do
          allow(handler).to receive(:event_mappings) { { 'some.event' => :something } }
        end

        it { expect(handler.send(:known_event?)).to be true }
      end

      context "when event mappings do not know about the event type" do
        before do
          allow(handler).to receive(:event_mappings) { { 'some.other.event' => :something } }
        end

        it { expect(handler.send(:known_event?)).to be false }
      end
    end

    describe "handle" do
      context "when the event is known" do
        before do
          allow(handler).to receive(:event_mappings) { { 'some.event' => :some_method } }
        end

        it "calls the handler method, and returns the result" do
          expect(handler).to receive(:some_method) { :result }
          expect(handler.handle).to eq :result
        end
      end

      context "when the event is unknown" do
        before do
          allow(handler).to receive(:event_mappings) { { 'some.other.event' => :some_method } }
        end

        it "does not call the handler method, and returns :unknown" do
          expect(handler).to_not receive(:some_method)
          expect(handler.handle).to be :unknown
        end
      end
    end

    describe "deauthorize" do
      context "when the event has no 'account' attribute" do
        it "does destroy stripe accounts, returns :ignored" do
          expect(handler).to_not receive(:destroy_stripe_accounts_linked_to)
          expect(handler.send(:deauthorize)).to be :ignored
        end
      end

      context "when the event has an 'account' attribute" do
        before do
          allow(event).to receive(:account) { 'some.account' }
        end

        context "when some stripe accounts are destroyed" do
          before do
            allow(handler).to receive(:destroy_stripe_accounts_linked_to).with('some.account') {
                                [double(:destroyed_stripe_account)]
                              }
          end

          it { expect(handler.send(:deauthorize)).to be :success }
        end

        context "when no stripe accounts are destroyed" do
          before do
            allow(handler).to receive(:destroy_stripe_accounts_linked_to).with('some.account') {
                                []
                              }
          end

          it { expect(handler.send(:deauthorize)).to be :ignored }
        end
      end
    end
  end
end
