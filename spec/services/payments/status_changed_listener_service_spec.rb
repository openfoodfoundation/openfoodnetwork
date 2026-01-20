# frozen_string_literal: true

RSpec.describe Payments::StatusChangedListenerService do
  let(:name) { "ofn.payment_transition" }
  let(:started) { Time.zone.parse("2025-11-28 09:00:00") }
  let(:finished) { Time.zone.parse("2025-11-28 09:00:02") }
  let(:unique_id) { "d3a7ac9f635755fcff2c" }
  let(:payload) { { payment:, event: "completed" } }
  let(:payment) { build(:payment) }

  subject { described_class.new }

  describe "#call" do
    it "calls Payments::WebhookService" do
      expect(Payments::WebhookService).to receive(:create_webhook_job).with(
        payment:, event: "payment.completed", at: started
      )

      subject.call(name, started, finished, unique_id, payload)
    end
  end
end
