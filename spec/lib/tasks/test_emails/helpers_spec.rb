# frozen_string_literal: true

require "spec_helper"
require "yaml"
require Rails.root.join("lib/tasks/test_emails/fake_blob")
require Rails.root.join("lib/tasks/test_emails/fake_subscription_summary")
require Rails.root.join("lib/tasks/test_emails/helpers")

RSpec.describe EmailTestHelpers do
  subject(:helper) { Object.new.extend(described_class) }

  describe "#load_email_config" do
    it "returns a deep copy of the defaults when the config file does not exist" do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?)
        .with(described_class::CONFIG_PATH)
        .and_return(false)

      config = helper.load_email_config

      expect(config).to eq(described_class::DEFAULT_CONFIG)
      expect(config).not_to equal(described_class::DEFAULT_CONFIG)
      expect(config["emails"]).not_to equal(described_class::DEFAULT_CONFIG["emails"])
    end

    it "merges a saved configuration with the defaults" do
      allow(File).to receive(:exist?)
        .with(described_class::CONFIG_PATH)
        .and_return(true)
      allow(YAML).to receive(:load_file)
        .with(described_class::CONFIG_PATH)
        .and_return("recipient" => "test@example.com")

      expect(helper.load_email_config).to eq(
        "recipient" => "test@example.com",
        "emails" => {}
      )
    end

    it "uses defaults when the saved YAML file is empty" do
      allow(File).to receive(:exist?)
        .with(described_class::CONFIG_PATH)
        .and_return(true)
      allow(YAML).to receive(:load_file)
        .with(described_class::CONFIG_PATH)
        .and_return(nil)

      expect(helper.load_email_config).to eq(described_class::DEFAULT_CONFIG)
    end
  end

  describe "#save_email_config" do
    it "writes the configuration as YAML" do
      config = { "recipient" => "test@example.com", "emails" => {} }

      expect(File).to receive(:write)
        .with(described_class::CONFIG_PATH, config.to_yaml)

      helper.save_email_config(config)
    end
  end

  describe "#configure_recipient" do
    it "updates the recipient when an address is entered" do
      allow($stdin).to receive(:gets).and_return("  test@example.com \n")

      result = helper.configure_recipient("recipient" => nil)

      expect(result["recipient"]).to eq("test@example.com")
    end

    it "keeps the current recipient when input is empty" do
      config = { "recipient" => "existing@example.com" }
      allow($stdin).to receive(:gets).and_return("\n")

      expect(helper.configure_recipient(config)).to equal(config)
    end
  end

  describe "#parse_selection_input" do
    it "parses comma-separated numbers" do
      expect(helper.parse_selection_input("1,3,5", 5)).to eq([1, 3, 5])
    end

    it "parses ranges" do
      expect(helper.parse_selection_input("2-4", 5)).to eq([2, 3, 4])
    end

    it "supports selecting all, case-insensitively" do
      expect(helper.parse_selection_input("ALL", 3)).to eq([1, 2, 3])
    end

    it "returns an empty selection for empty input" do
      expect(helper.parse_selection_input("", 3)).to eq([])
    end
  end

  describe "#parse_selection_part" do
    it "parses a single index" do
      expect(helper.parse_selection_part("3")).to eq(3)
    end

    it "parses a range" do
      expect(helper.parse_selection_part("2-4")).to eq([2, 3, 4])
    end
  end

  describe "#build_email_config" do
    it "marks selected keys true and all others false" do
      expect(helper.build_email_config(%w[a b c], [1, 3])).to eq(
        "a" => true,
        "b" => false,
        "c" => true
      )
    end

    it "ignores indexes outside the available keys" do
      expect(helper.build_email_config(%w[a b], [1, 3])).to eq(
        "a" => true,
        "b" => false
      )
    end

    it "leaves all keys disabled when no indexes are selected" do
      expect(helper.build_email_config(%w[a b], [])).to eq(
        "a" => false,
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
        def _internal; end
      end
    end

    it "returns sorted public actions excluding mail and underscore-prefixed methods" do
      expect(helper.get_mailer_actions(mailer_class)).to eq(%w[first_email second_email])
    end
  end

  describe "#build_email_config" do
    it "handles an empty list of available email keys" do
      expect(helper.build_email_config([], [1])).to eq({})
    end
  end

  describe "#optional_default" do
    it "uses false for resend arguments" do
      expect(helper.optional_default(:resend_email)).to be(false)
    end

    it "uses an empty hash for options-like arguments" do
      %i[options option opts params].each do |name|
        expect(helper.optional_default(name)).to eq({})
      end
    end

    it "uses nil for other optional arguments" do
      expect(helper.optional_default(:delivery)).to be_nil
    end
  end

  describe "#keyword_argument?" do
    it "recognizes required and optional keyword parameters" do
      expect(helper.keyword_argument?(:keyreq)).to be(true)
      expect(helper.keyword_argument?(:key)).to be(true)
    end

    it "does not recognize positional parameters as keywords" do
      expect(helper.keyword_argument?(:req)).to be(false)
      expect(helper.keyword_argument?(:opt)).to be(false)
    end
  end

  describe "#default_value_for" do
    it "returns the missing marker for a required argument" do
      expect(helper.default_value_for(:req, :user)).to eq(:__missing__)
    end

    it "returns the default for an optional argument" do
      expect(helper.default_value_for(:key, :options)).to eq({})
    end
  end

  describe "#provider_for" do
    it "returns a configured provider for a known argument" do
      expect(helper.provider_for(:token)).to eq(described_class::TEST_DATA[:token])
    end

    it "uses fallback matching for names containing a known concept" do
      expect(helper.provider_for(:order_number)).to eq(described_class::TEST_DATA[:order])
    end

    it "returns nil when there is no provider" do
      expect(helper.provider_for(:unknown_parameter)).to be_nil
    end
  end

  describe "#fallback_provider" do
    it "finds a provider from a fallback matcher" do
      expect(helper.fallback_provider(:shipment_status))
        .to eq(described_class::TEST_DATA[:shipment])
    end

    it "returns nil when no fallback matcher matches" do
      expect(helper.fallback_provider(:unknown_parameter)).to be_nil
    end
  end

  describe "#argument_value" do
    before do
      helper.instance_variable_set(:@user, :sample_user)
    end

    it "uses the provider for a known argument" do
      expect(helper.argument_value(:req, :user)).to eq(:sample_user)
    end

    it "uses the default for an optional unknown argument" do
      expect(helper.argument_value(:opt, :unknown)).to be_nil
    end

    it "returns the missing marker for a required unknown argument" do
      expect(helper.argument_value(:req, :unknown)).to eq(:__missing__)
    end
  end

  describe "#build_arguments" do
    it "builds argument tuples from a method signature" do
      method = double("Method", parameters: [[:req, :user], [:key, :options]])
      allow(helper).to receive(:argument_value).with(:req, :user).and_return(:user_value)
      allow(helper).to receive(:argument_value).with(:key, :options).and_return({})

      expect(helper.build_arguments(method)).to eq(
        [[:req, :user, :user_value], [:key, :options, {}]]
      )
    end

    it "raises when required test data is missing" do
      method = double("Method", parameters: [[:req, :unconfigured_argument]])
      allow(helper).to receive(:argument_value).and_return(:__missing__)

      expect { helper.build_arguments(method) }
        .to raise_error("No test data configured for :unconfigured_argument")
    end
  end

  describe "#build_mail_arguments" do
    it "separates positional and keyword arguments" do
      method = double("Method", parameters: [
                        [:req, :user], [:keyreq, :token], [:key, :options]
                      ])
      allow(helper).to receive(:build_arguments).with(method).and_return([
                                                                           [:req, :user,
                                                                            :user_value],
                                                                           [:keyreq, :token, "abc"],
                                                                           [:key, :options, {}]
                                                                         ])

      expect(helper.build_mail_arguments(method)).to eq(
        [[:user_value], { token: "abc", options: {} }]
      )
    end
  end

  describe "#override_recipient" do
    let(:mail) { double("Mail") }

    it "overrides to and clears cc/bcc when a recipient is configured" do
      allow(helper).to receive(:load_email_config)
        .and_return("recipient" => "test@example.com")
      expect(mail).to receive(:to=).with(["test@example.com"])
      expect(mail).to receive(:cc=).with(nil)
      expect(mail).to receive(:bcc=).with(nil)

      helper.override_recipient(mail)
    end

    it "does nothing when no recipient is configured" do
      allow(helper).to receive(:load_email_config).and_return("recipient" => nil)

      expect(mail).not_to receive(:to=)
      expect(mail).not_to receive(:cc=)
      expect(mail).not_to receive(:bcc=)

      helper.override_recipient(mail)
    end
  end

  describe "#deliver_mail" do
    let(:mail) { double("Mail", deliver_now: true) }
    let(:mailer_class) { double("Mailer") }

    it "calls mailer with positional and keyword arguments, overrides the recipient and delivers" do
      expect(mailer_class).to receive(:test_email).with(:argument, token: "abc").and_return(mail)
      expect(helper).to receive(:override_recipient).with(mail)

      expect(helper.deliver_mail(mailer_class, :test_email, [:argument],
                                 { token: "abc" })).to be(true)
    end

    it "calls the mailer without keyword arguments when none are supplied" do
      expect(mailer_class).to receive(:test_email).with(:argument).and_return(mail)
      allow(helper).to receive(:override_recipient)

      helper.deliver_mail(mailer_class, :test_email, [:argument], {})
    end
  end

  describe "#send_dynamic_email" do
    it "builds arguments from the action signature and delivers the email" do
      mailer_class = Class.new do
        def self.test_email(_user, _token:)
          Struct.new(:delivered) do
            def deliver_now
              self.delivered = true
            end
          end.new(false)
        end

        def self.instance_method(action)
          new.method(action)
        end

        def test_email(_user, token:); end
      end
      allow(helper).to receive(:build_mail_arguments).and_return([[:sample_user], { token: "abc" }])
      allow(helper).to receive(:deliver_mail).and_return(:delivered)

      expect(helper.send_dynamic_email(mailer_class, :test_email)).to eq(:delivered)
    end
  end

  describe "#send_test_email" do
    it "uses the dynamic sender when no special handler is registered" do
      mailer_class = Class.new
      allow(helper).to receive(:send_dynamic_email).with(mailer_class,
                                                         :ordinary_email).and_return(:sent)

      expect(helper.send_test_email(mailer_class, :ordinary_email)).to eq(:sent)
    end
  end

  describe "#send_summary_email" do
    it "creates a fake summary and delivers the selected summary email" do
      distributor = double("Distributor", id: 7)
      order = double("Order", id: 42)
      mail = double("Mail", deliver_now: :delivered)
      mailer = double("SubscriptionMailer")
      allow(helper).to receive(:instance_variable_get).and_call_original
      helper.instance_variable_set(:@distributor, distributor)
      helper.instance_variable_set(:@order, order)
      expect(mailer).to receive(:placement_summary_email) do |summary|
        expect(summary).to be_a(FakeSubscriptionSummary)
        expect(summary.shop_id).to eq(7)
        expect(summary.type).to eq(:placement)
        expect(summary.orders).to be_nil if summary.respond_to?(:orders)
        mail
      end

      expect(helper.send_summary_email(mailer, :placement_summary_email,
                                       :placement)).to eq(:delivered)
    end
  end

  describe "#print_header" do
    it "prints the title between divider lines" do
      expect { helper.print_header("Email test") }.to output(/Email test/).to_stdout
    end
  end

  describe "#print_footer" do
    it "prints totals and errors" do
      expect { helper.print_footer(2, 1) }
        .to output(/Total emails sent: 2.*Errors encountered: 1/m).to_stdout
    end
  end
end
