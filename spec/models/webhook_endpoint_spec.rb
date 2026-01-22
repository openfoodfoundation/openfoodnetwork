# frozen_string_literal: true

RSpec.describe WebhookEndpoint do
  describe "validations" do
    it { is_expected.to validate_presence_of(:url) }
    it {
      is_expected.to validate_inclusion_of(:webhook_type)
        .in_array(%w(order_cycle_opened payment_status_changed))
    }
  end
end
