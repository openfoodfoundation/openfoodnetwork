# frozen_string_literal: true

require "spec_helper"

require Rails.root.join("lib/tasks/test_emails/fake_blob")
require Rails.root.join("lib/tasks/test_emails/fake_subscription_summary")
require Rails.root.join("lib/tasks/test_emails/helpers")

RSpec.describe FakeBlob do
  subject(:blob) { described_class.new }

  it "provides a filename" do
    expect(blob.filename).to eq("test-report.csv")
  end

  it "provides a service URL" do
    expect(blob.expiring_service_url).to eq("http://example.com/test-report.csv")
  end
end

RSpec.describe FakeSubscriptionSummary do
  let(:order) { double("Order", id: 42) }

  subject(:summary) do
    described_class.new(
      shop_id: 7,
      type: :confirmation,
      orders: [order]
    )
  end

  describe "attributes" do
    it "exposes the shop ID and summary type" do
      expect(summary.shop_id).to eq(7)
      expect(summary.type).to eq(:confirmation)
    end
  end

  describe "counts" do
    it "returns the expected order and issue counts" do
      expect(summary.order_count).to eq(1)
      expect(summary.issue_count).to eq(1)
      expect(summary.success_count).to eq(0)
    end
  end

  describe "issues" do
    it "reports the payment issue for the order" do
      expect(summary.issues).to eq(
        payment: { 42 => "Payment failed" }
      )
    end

    it "returns the affected orders" do
      expect(summary.orders_affected_by(:payment)).to eq([order])
    end

    it "returns no unrecorded IDs" do
      expect(summary.unrecorded_ids).to eq([])
    end

    it "returns no subscription issues" do
      expect(summary.subscription_issues).to eq([])
    end
  end
end

RSpec.describe EmailTestHelpers do
  subject(:helper) { Object.new.extend(described_class) }

  describe "#load_email_config" do
    it "returns a copy of the default configuration when no file exists" do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?)
        .with(EmailTestHelpers::CONFIG_PATH)
        .and_return(false)

      config = helper.load_email_config

      expect(config).to eq(described_class::DEFAULT_CONFIG)
      expect(config).not_to equal(described_class::DEFAULT_CONFIG)
    end
  end

  describe "#parse_selection_input" do
    it "parses comma-separated selections" do
      expect(helper.parse_selection_input("1,3,5", 5)).to eq([1, 3, 5])
    end

    it "parses ranges" do
      expect(helper.parse_selection_input("2-4", 5)).to eq([2, 3, 4])
    end

    it "supports selecting all emails" do
      expect(helper.parse_selection_input("all", 3)).to eq([1, 2, 3])
    end

    it "supports selecting all emails regardless of case" do
      expect(helper.parse_selection_input("ALL", 2)).to eq([1, 2])
    end
  end

  describe "#build_email_config" do
    it "selects the requested emails and disables the others" do
      expect(helper.build_email_config(%w[a b c], [1, 3])).to eq(
        "a" => true,
        "b" => false,
        "c" => true
      )
    end

    it "returns an entirely unselected configuration for an empty selection" do
      expect(helper.build_email_config(%w[a b], [])).to eq(
        "a" => false,
        "b" => false
      )
    end

    it "ignores indexes outside the available emails" do
      expect(helper.build_email_config(%w[a b], [1, 3])).to eq(
        "a" => true,
        "b" => false
      )
    end
  end

  describe "#get_mailer_actions" do
    let(:mailer_class) do
      Class.new do
        def first_email; end

        def second_email; end

        def mail; end

        def _internal_method; end
      end
    end

    it "returns sorted public actions excluding internal methods and mail" do
      expect(helper.get_mailer_actions(mailer_class)).to eq(
        %w[first_email second_email]
      )
    end
  end

  describe "#optional_default" do
    it "returns false for resend arguments" do
      expect(helper.optional_default(:resend_email)).to be(false)
    end

    it "returns an empty hash for options arguments" do
      expect(helper.optional_default(:options)).to eq({})
    end

    it "returns nil for other optional arguments" do
      expect(helper.optional_default(:delivery)).to be_nil
    end
  end

  describe "#keyword_argument?" do
    it "identifies required and optional keyword arguments" do
      expect(helper.keyword_argument?(:keyreq)).to be(true)
      expect(helper.keyword_argument?(:key)).to be(true)
    end

    it "does not identify positional arguments as keywords" do
      expect(helper.keyword_argument?(:req)).to be(false)
      expect(helper.keyword_argument?(:opt)).to be(false)
    end
  end

  describe "#build_email_config" do
    it "does not select an email when no indexes are provided" do
      expect(helper.build_email_config(%w[a b], [])).to eq(
        "a" => false,
        "b" => false
      )
    end
  end
end
