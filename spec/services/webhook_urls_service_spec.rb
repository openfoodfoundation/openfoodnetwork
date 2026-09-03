# frozen_string_literal: true

RSpec.describe WebhookUrlsService do
  subject { described_class.for_coordinator(coordinator, webhook_type: "payment_status_changed") }

  let(:coordinator) { create(:enterprise) }

  it "returns nothing when no endpoint is configured" do
    expect(subject).to eq []
  end

  it "returns the endpoints of the coordinator owner" do
    coordinator.owner.webhook_endpoints.payment_status.create!(url: "http://owner.url")

    expect(subject).to eq ["http://owner.url"]
  end

  it "returns the endpoints of the coordinator managers" do
    manager = create(:user)
    coordinator.users << manager
    manager.webhook_endpoints.payment_status.create!(url: "http://manager.url")

    expect(subject).to eq ["http://manager.url"]
  end

  it "ignores duplicate urls" do
    manager = create(:user)
    coordinator.users << manager
    coordinator.owner.webhook_endpoints.payment_status.create!(url: "http://shared.url")
    manager.webhook_endpoints.payment_status.create!(url: "http://shared.url")

    expect(subject).to eq ["http://shared.url"]
  end

  it "ignores endpoints configured for another webhook type" do
    coordinator.owner.webhook_endpoints.order_cycle_opened.create!(url: "http://order.cycle.url")

    expect(subject).to eq []
  end
end
