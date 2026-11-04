# frozen_string_literal: true

require "spec_helper"

RSpec.describe "EmailTestData" do
  before(:all) do
    rake_file = Rails.root.join("lib/tasks/test_emails.rake")

    unless Rake::Task.task_defined?("ofn:test_emails")
      load rake_file
    end
  end

  describe "ofn:test_emails task" do
    let(:email_test_data_class) { Object.const_get(:EmailTestData) }
    let(:email_test_data) { instance_double(email_test_data_class, run: nil) }

    before do
      allow(email_test_data_class).to receive(:new).and_return(email_test_data)
    end

    it "ensures sample data exists before sending emails" do
      task = Rake::Task["ofn:test_emails"]
      task.reenable

      allow(Spree::Order).to receive(:any?).and_return(false)
      allow(Enterprise).to receive(:any?).and_return(false)

      sample_task = instance_double(Rake::Task)
      allow(sample_task).to receive(:invoke)

      allow(Rake::Task).to receive(:[]).and_call_original
      allow(Rake::Task).to receive(:[])
        .with("ofn:sample_data")
        .and_return(sample_task)

      task.invoke

      expect(sample_task).to have_received(:invoke).once
      expect(email_test_data).to have_received(:run).once
    end

    it "skips sample_data generation when it already exists" do
      task = Rake::Task["ofn:test_emails"]
      task.reenable

      allow(Spree::Order).to receive(:any?).and_return(true)
      allow(Enterprise).to receive(:any?).and_return(true)

      expect(Rake::Task).not_to receive(:[])
        .with("ofn:sample_data")

      task.invoke

      expect(email_test_data).to have_received(:run).once
    end
  end

  describe "Configuration" do
    let(:configuration_class) do
      Object.const_get(:EmailTestData)::Configuration
    end

    subject(:config) { configuration_class.new }

    describe "#load_email_config" do
      before do
        allow(File).to receive(:exist?).and_call_original
      end

      it "returns the default config when the file is missing" do
        allow(File).to receive(:exist?)
          .with(configuration_class::CONFIG_PATH)
          .and_return(false)

        expect(config.load_email_config).to eq(
          configuration_class::DEFAULT_CONFIG.deep_dup
        )
      end

      it "merges YAML config when the file exists" do
        allow(File).to receive(:exist?)
          .with(configuration_class::CONFIG_PATH)
          .and_return(true)

        allow(YAML).to receive(:load_file)
          .with(configuration_class::CONFIG_PATH)
          .and_return({ "recipient" => "x@example.com" })

        expected_config = configuration_class::DEFAULT_CONFIG.deep_dup
          .deep_merge({ "recipient" => "x@example.com" })

        expect(config.load_email_config).to eq(expected_config)
      end
    end

    describe "#save_email_config" do
      it "writes the YAML file" do
        config_hash = { "recipient" => "a" }

        expect(File).to receive(:write).with(
          configuration_class::CONFIG_PATH,
          config_hash.to_yaml
        )

        config.save_email_config(config_hash)
      end
    end

    describe "#configure_recipient" do
      before do
        allow($stdout).to receive(:puts)
        allow($stdout).to receive(:print)
      end

      it "keeps the current config when input is blank" do
        allow($stdin).to receive(:gets).and_return("\n")

        current = { "recipient" => "old@example.com" }

        expect(config.configure_recipient(current)).to eq(current)
      end

      it "updates the recipient when input is provided" do
        allow($stdin).to receive(:gets)
          .and_return("new@example.com\n")

        current = { "recipient" => "old@example.com" }

        expect(config.configure_recipient(current)).to eq(
          "recipient" => "new@example.com"
        )
      end
    end
  end

  describe "Configuration selection" do
    let(:configuration_class) do
      Object.const_get(:EmailTestData)::Configuration
    end

    subject(:config) { configuration_class.new }

    before do
      allow($stdout).to receive(:puts)
      allow($stdout).to receive(:print)
    end

    describe "#configure_recipient" do
      it "shows the message when no recipient is currently configured" do
        allow($stdin).to receive(:gets).and_return("new@example.com\n")

        result = config.configure_recipient("recipient" => nil)

        expect($stdout).to have_received(:puts)
          .with("Currently no recipient configured.")
        expect(result).to eq("recipient" => "new@example.com")
      end
    end

    describe "#display_available_emails" do
      it "returns all email keys and marks the selected ones" do
        selected_key = configuration_class::EMAIL_KEYS.first
        allow(config).to receive(:load_email_config).and_return(
          "emails" => { selected_key => true }
        )

        result = config.display_available_emails

        expect(result).to eq(configuration_class::EMAIL_KEYS)
        expect($stdout).to have_received(:puts)
          .with(format("%2d. [x] %s", 1, selected_key))
        expect($stdout).to have_received(:puts)
          .with(format("%2d. [ ] %s", 2, configuration_class::EMAIL_KEYS.second))
      end
    end

    describe "#print_selection_help" do
      it "prints the supported selection formats" do
        config.print_selection_help

        expect($stdout).to have_received(:puts).with("Examples:")
        expect($stdout).to have_received(:puts).with("  1,4,7")
        expect($stdout).to have_received(:puts).with("  1-5")
        expect($stdout).to have_received(:puts).with("  all")
        expect($stdout).to have_received(:puts)
          .with("  empty input keeps current selection")
        expect($stdout).to have_received(:print)
          .with("Select emails to send: ")
      end
    end

    describe "#parse_selection_input" do
      it "selects every index when input is all, regardless of case" do
        expect(config.parse_selection_input("ALL", 4)).to eq([1, 2, 3, 4])
      end

      it "parses comma-separated indexes and ranges" do
        expect(config.parse_selection_input("1, 3-5, 7", 7)).to eq(
          [1, 3, 4, 5, 7]
        )
      end
    end

    describe "#build_email_config" do
      it "marks selected indexes and ignores indexes without a matching key" do
        result = config.build_email_config(%w[first second third], [1, 3, 99])

        expect(result).to eq(
          "first" => true,
          "second" => false,
          "third" => true
        )
      end
    end
  end

  describe "EmailTestData instance methods" do
    let(:email_test_data_class) { Object.const_get(:EmailTestData) }
    let(:configuration_class) { email_test_data_class::Configuration }

    subject(:email_test_data) { email_test_data_class.new }

    before do
      allow($stdout).to receive(:puts)
      allow($stdout).to receive(:print)
    end

    def stub_run_configuration(config:, email_keys:, input:)
      configuration = instance_double(configuration_class)

      allow(configuration_class).to receive(:new).and_return(configuration)
      allow(configuration).to receive(:load_email_config).and_return(config)
      allow(configuration).to receive(:configure_recipient).and_return(config)
      allow(configuration).to receive(:display_available_emails).and_return(email_keys)
      allow(configuration).to receive(:print_selection_help)
      allow(configuration).to receive(:save_email_config)
      allow($stdin).to receive(:gets).and_return(input)

      configuration
    end

    describe "#print_header" do
      it "prints a title surrounded by a matching divider" do
        email_test_data.print_header("Email tests")

        expect($stdout).to have_received(:puts).with("\n===========")
        expect($stdout).to have_received(:puts).with("Email tests")
        expect($stdout).to have_received(:puts).with("===========")
      end
    end

    describe "#print_footer" do
      it "prints the totals and closing divider" do
        email_test_data.print_footer("Complete", 3, 1)

        expect($stdout).to have_received(:puts).with("\n========")
        expect($stdout).to have_received(:puts).with("Complete")
        expect($stdout).to have_received(:puts).with("Total emails sent: 3")
        expect($stdout).to have_received(:puts).with("Errors encountered: 1")
        expect($stdout).to have_received(:puts).with("========\n")
      end
    end

    describe "#run" do
      let(:email_keys) { %w[first second] }

      it "uses the parsed indexes when the user enters a selection" do
        initial_config = { "recipient" => "test@example.com", "emails" => {} }
        selected_config = { "first" => false, "second" => true }
        configuration = stub_run_configuration(
          config: initial_config,
          email_keys: email_keys,
          input: "2\n"
        )
        allow(configuration).to receive(:parse_selection_input)
          .with("2", 2).and_return([2])
        allow(configuration).to receive(:build_email_config)
          .with(email_keys, [2]).and_return(selected_config)

        expected_config = initial_config.merge("emails" => selected_config)
        expect(configuration).to receive(:save_email_config).with(expected_config)
        expect(email_test_data).to receive(:send_selected_emails)
          .with(selected_config, 0, 0).and_return([3, 2])
        expect(email_test_data).to receive(:print_footer)
          .with("Email Layout Test Suite Complete", 3, 2)

        email_test_data.run
      end

      it "keeps an existing selection when the user enters nothing" do
        existing_selection = { "first" => true, "second" => false }
        initial_config = {
          "recipient" => "test@example.com",
          "emails" => existing_selection
        }
        configuration = stub_run_configuration(
          config: initial_config,
          email_keys: email_keys,
          input: "\n"
        )

        expect(configuration).not_to receive(:build_email_config)
        expect(configuration).to receive(:save_email_config).with(initial_config)
        expect(email_test_data).to receive(:send_selected_emails)
          .with(existing_selection, 0, 0).and_return([0, 0])

        email_test_data.run
      end

      it "selects every email by default when there is no saved selection" do
        initial_config = { "recipient" => "test@example.com", "emails" => {} }
        all_selected = { "first" => true, "second" => true }
        configuration = stub_run_configuration(
          config: initial_config,
          email_keys: email_keys,
          input: "\n"
        )
        allow(configuration).to receive(:build_email_config)
          .with(email_keys, [1, 2]).and_return(all_selected)

        expected_config = initial_config.merge("emails" => all_selected)
        expect(configuration).to receive(:save_email_config).with(expected_config)
        expect(email_test_data).to receive(:send_selected_emails)
          .with(all_selected, 0, 0).and_return([0, 0])

        email_test_data.run
      end
    end

    describe "#send_selected_emails" do
      it "sends selected emails and reports errors without stopping the loop" do
        successful_key, failing_key = email_test_data_class::EMAIL_KEYS.first(2)
        email_sender = instance_double(email_test_data_class::EmailSender)

        expect(email_test_data_class::EmailSender).to receive(:new)
          .with(email_test_data).twice.and_return(email_sender)
        expect(email_sender).to receive(:send_email_for)
          .with(successful_key).and_return(double("delivered mail"))
        expect(email_sender).to receive(:send_email_for)
          .with(failing_key).and_raise(StandardError, "delivery failed")
        expect(email_test_data).to receive(:puts).with("✓ #{successful_key}")
        expect(email_test_data).to receive(:puts)
          .with("❌ #{failing_key}: StandardError - delivery failed")

        result = email_test_data.send_selected_emails(
          { successful_key => true, failing_key => true },
          0,
          0
        )

        expect(result).to eq([1, 1])
      end

      it "does not count a selected email when no mail is generated" do
        key = email_test_data_class::EMAIL_KEYS.first
        email_sender = instance_double(email_test_data_class::EmailSender)

        allow(email_test_data_class::EmailSender).to receive(:new)
          .with(email_test_data).and_return(email_sender)
        allow(email_sender).to receive(:send_email_for).with(key).and_return(nil)
        expect(email_test_data).to receive(:puts)
          .with("↷ #{key}: no email generated")

        result = email_test_data.send_selected_emails({ key => true }, 2, 1)

        expect(result).to eq([2, 1])
      end
    end

    describe "#load_email_config" do
      it "delegates to the configuration object" do
        settings = { "recipient" => "test@example.com" }
        configuration = instance_double(configuration_class, load_email_config: settings)
        expect(configuration_class).to receive(:new).and_return(configuration)

        expect(email_test_data.load_email_config).to eq(settings)
      end
    end

    describe "#sample_data" do
      it "creates and memoizes the sample data object" do
        expect(email_test_data_class::SampleData).to receive(:new)
          .with(email_test_data).once.and_call_original

        first = email_test_data.sample_data

        expect(email_test_data.sample_data).to equal(first)
      end
    end
  end

  describe "EmailSenderHelpers" do
    let(:helpers) { Object.const_get(:EmailTestData)::EmailSenderHelpers }

    describe ".backorder_incomplete" do
      it "builds the backorder email when all required associations exist" do
        user = double("user")
        order_cycle = double("order cycle")
        distributor = double("distributor", owner: user, permalink: "local-farm")
        order = double(
          "order",
          distributor: distributor,
          order_cycle: order_cycle,
          id: 42
        )
        data = double("sample data", sample_order: order)
        mail = double("mail")

        expect(BackorderMailer).to receive(:backorder_incomplete).with(
          user,
          distributor,
          order_cycle,
          "https://example.org/api/dfc/Enterprises/local-farm/Orders/42"
        ).and_return(mail)

        expect(helpers.backorder_incomplete(data)).to eq(mail)
      end

      it "returns nil when a required association is missing" do
        user = double("user")
        order_cycle = double("order cycle")
        distributor_without_owner = double("distributor", owner: nil)
        distributor = double("distributor", owner: user)

        orders = [
          double("order", distributor: nil, order_cycle: order_cycle),
          double(
            "order",
            distributor: distributor_without_owner,
            order_cycle: order_cycle
          ),
          double("order", distributor: distributor, order_cycle: nil)
        ]

        expect(BackorderMailer).not_to receive(:backorder_incomplete)

        orders.each do |order|
          expect(helpers.backorder_incomplete(double(sample_order: order))).to be_nil
        end
      end
    end

    describe ".report_ready" do
      let(:data) { double("sample data", test_recipient: "test@example.com") }
      let(:mailer) { double("parameterized report mailer") }
      let(:mail) { double("mail") }

      it "uses the most recent report blob when one exists" do
        report_blob = double("report blob")
        expect(ReportBlob).to receive(:last).and_return(report_blob)
        expect(ReportBlob).not_to receive(:create_locally!)
        expect(ReportMailer).to receive(:with)
          .with(to: "test@example.com", blob: report_blob).and_return(mailer)
        expect(mailer).to receive(:report_ready).and_return(mail)

        expect(helpers.report_ready(data)).to eq(mail)
      end

      it "creates a report blob when none exists" do
        report_blob = double("report blob")
        expect(ReportBlob).to receive(:last).and_return(nil)
        expect(ReportBlob).to receive(:create_locally!)
          .with("sample_report.csv", "sample report").and_return(report_blob)
        expect(ReportMailer).to receive(:with)
          .with(to: "test@example.com", blob: report_blob).and_return(mailer)
        expect(mailer).to receive(:report_ready).and_return(mail)

        expect(helpers.report_ready(data)).to eq(mail)
      end
    end
  end

  describe "EmailSender" do
    let(:email_test_data_class) { Object.const_get(:EmailTestData) }
    let(:sender_class) { email_test_data_class::EmailSender }
    let(:email_sender) { sender_class.new(data) }
    let(:sample_order) { double("sample order") }
    let(:sample_shipment) { double("sample shipment") }
    let(:sample_user) { double("sample user") }
    let(:sample_enterprise) { double("sample enterprise") }
    let(:sample_payment) { double("sample payment") }
    let(:sample_producer) { double("sample producer") }
    let(:sample_order_cycle) { double("sample order cycle") }
    let(:subscription_summary) { double("subscription summary") }
    let(:data) do
      double(
        "sample data",
        sample_order: sample_order,
        sample_shipment: sample_shipment,
        sample_user: sample_user,
        sample_enterprise: sample_enterprise,
        sample_payment: sample_payment,
        sample_producer: sample_producer,
        sample_order_cycle: sample_order_cycle,
        subscription_summary: subscription_summary,
        test_recipient: "test@example.com"
      )
    end

    describe "#send_email_for" do
      it "invokes every configured sender and delivers each email to the test recipient" do
        message = double("message")
        mail = double("mail", message: message)
        sender_specs = [
          [BackorderMailer, :backorder_failed, [sample_order]],
          [EnterpriseMailer, :manager_invitation, [sample_enterprise, sample_user]],
          [EnterpriseMailer, :welcome, [sample_enterprise]],
          [PaymentMailer, :authorization_required, [sample_payment]],
          [PaymentMailer, :authorize_payment, [sample_payment]],
          [PaymentMailer, :refund_available,
           [10.0, sample_payment, "http://example.com/status"]],
          [ProducerMailer, :order_cycle_report, [sample_producer, sample_order_cycle]],
          [Spree::OrderMailer, :cancel_email, [sample_order]],
          [Spree::OrderMailer, :cancel_email_for_shop, [sample_order]],
          [Spree::OrderMailer, :confirm_email_for_customer, [sample_order]],
          [Spree::OrderMailer, :confirm_email_for_shop, [sample_order]],
          [Spree::OrderMailer, :invoice_email, [sample_order]],
          [Spree::TestMailer, :test_email, [sample_user]],
          [Spree::UserMailer, :confirmation_instructions, [sample_user, "test_token"]],
          [Spree::UserMailer, :reset_password_instructions, [sample_user, "test_token"]],
          [Spree::UserMailer, :signup_confirmation, [sample_user]],
          [SubscriptionMailer, :confirmation_email, [sample_order]],
          [SubscriptionMailer, :confirmation_summary_email, [subscription_summary]],
          [SubscriptionMailer, :empty_email, [sample_order, []]],
          [SubscriptionMailer, :failed_payment_email, [sample_order]],
          [SubscriptionMailer, :placement_email, [sample_order, []]],
          [SubscriptionMailer, :placement_summary_email, [subscription_summary]]
        ]

        sender_specs.each do |mailer, action, arguments|
          expect(mailer).to receive(action).with(*arguments).and_return(mail)
        end
        expect(Spree::ShipmentMailer).to receive(:shipped_email)
          .with(sample_shipment, delivery: true).and_return(mail)
        expect(Spree::ShipmentMailer).to receive(:shipped_email)
          .with(sample_shipment, delivery: false).and_return(mail)
        expect(EmailTestData::EmailSenderHelpers).to receive(:backorder_incomplete)
          .with(data).and_return(mail)
        expect(EmailTestData::EmailSenderHelpers).to receive(:report_ready)
          .with(data).and_return(mail)
        expect(message).to receive(:to=)
          .with("test@example.com").exactly(email_test_data_class::EMAIL_KEYS.size).times
        expect(mail).to receive(:deliver_now)
          .exactly(email_test_data_class::EMAIL_KEYS.size).times

        email_test_data_class::EmailSender::SENDERS.each_key do |key|
          email_sender.send_email_for(key)
        end
      end

      it "raises an error for a key without a configured sender" do
        expect { email_sender.send_email_for("UnknownMailer#unknown_email") }
          .to raise_error("No sender defined for UnknownMailer#unknown_email")
      end

      it "returns without delivery when the sender does not produce an email" do
        allow(BackorderMailer).to receive(:backorder_failed)
          .with(sample_order).and_return(nil)
        expect(data).not_to receive(:test_recipient)

        expect(email_sender.send_email_for("BackorderMailer#backorder_failed")).to be_nil
      end

      it "raises an error when no test recipient is configured" do
        data_without_recipient = double(
          "sample data",
          sample_order: sample_order,
          test_recipient: nil
        )
        mail = double("mail", message: double("message"))
        allow(BackorderMailer).to receive(:backorder_failed).and_return(mail)

        sender = sender_class.new(data_without_recipient)

        expect { sender.send_email_for("BackorderMailer#backorder_failed") }
          .to raise_error("No test recipient configured!")
      end
    end
  end

  describe "SampleData" do
    let(:email_test_data_class) { Object.const_get(:EmailTestData) }
    let(:sample_data_class) { email_test_data_class::SampleData }
    let(:config) {
      double("configuration", load_email_config: { "recipient" => "test@example.com" })
    }

    subject(:sample_data) { sample_data_class.new(config) }

    describe "#subscription_summary" do
      it "records the sample order and its successful payment in a summary" do
        distributor = double("distributor", id: 123)
        order = double("order")
        summary = double("subscription summary")

        allow(sample_data).to receive(:sample_distributor).and_return(distributor)
        allow(sample_data).to receive(:sample_order).and_return(order)
        expect(OrderManagement::Subscriptions::Summary).to receive(:new)
          .with(123).and_return(summary)
        expect(summary).to receive(:record_order).with(order)
        expect(summary).to receive(:record_success).with(order)

        expect(sample_data.subscription_summary).to eq(summary)
      end
    end

    describe "#sample_order" do
      it "returns and memoizes a completed order that has line items" do
        order_scope = double("completed orders")
        order = double("order", line_items: [double("line item")])
        allow(Spree::Order).to receive(:complete).and_return(order_scope)
        allow(order_scope).to receive(:includes).with(:line_items).and_return([order])

        expect(sample_data.sample_order).to eq(order)
        expect(sample_data.sample_order).to equal(order)
      end

      it "falls back to the most recent order when no completed order has line items" do
        order_scope = double("completed orders")
        fallback_scope = double("ordered orders")
        order_without_items = double("order without line items", line_items: [])
        fallback_order = double("fallback order")

        allow(Spree::Order).to receive(:complete).and_return(order_scope)
        allow(order_scope).to receive(:includes)
          .with(:line_items).and_return([order_without_items])
        allow(Spree::Order).to receive(:order).with(:id).and_return(fallback_scope)
        allow(fallback_scope).to receive(:last).and_return(fallback_order)

        expect(sample_data.sample_order).to eq(fallback_order)
      end
    end

    describe "#sample_shipment" do
      it "returns and memoizes the most recent shipment" do
        shipment_scope = double("shipments")
        ordered_scope = double("ordered shipments")
        shipment = double("shipment")
        allow(Spree::Shipment).to receive(:includes)
          .with(:order).and_return(shipment_scope)
        allow(shipment_scope).to receive(:order).with(:id).and_return(ordered_scope)
        allow(ordered_scope).to receive(:last).and_return(shipment)

        expect(sample_data.sample_shipment).to eq(shipment)
        expect(sample_data.sample_shipment).to equal(shipment)
      end
    end

    describe "#sample_user" do
      it "uses the most recent user when one exists" do
        user_scope = double("users")
        user = double("user")
        allow(Spree::User).to receive(:order).with(:id).and_return(user_scope)
        allow(user_scope).to receive(:last).and_return(user)

        expect(sample_data.sample_user).to eq(user)
      end

      it "falls back to the first user when the ordered query is empty" do
        user_scope = double("users")
        user = double("first user")
        allow(Spree::User).to receive(:order).with(:id).and_return(user_scope)
        allow(user_scope).to receive(:last).and_return(nil)
        allow(Spree::User).to receive(:first).and_return(user)

        expect(sample_data.sample_user).to eq(user)
      end

      it "falls back to the sample order's user when no users are found" do
        user_scope = double("users")
        order = double("order", user: double("order user"))
        allow(Spree::User).to receive(:order).with(:id).and_return(user_scope)
        allow(user_scope).to receive(:last).and_return(nil)
        allow(Spree::User).to receive(:first).and_return(nil)
        allow(sample_data).to receive(:sample_order).and_return(order)

        expect(sample_data.sample_user).to eq(order.user)
      end
    end

    describe "#sample_enterprise" do
      it "uses the order distributor when present" do
        distributor = double("distributor")
        allow(sample_data).to receive(:sample_order)
          .and_return(double("order", distributor: distributor))

        expect(sample_data.sample_enterprise).to eq(distributor)
      end

      it "falls back to the most recent enterprise" do
        enterprise_scope = double("enterprises")
        enterprise = double("enterprise")
        allow(sample_data).to receive(:sample_order)
          .and_return(double("order", distributor: nil))
        allow(Enterprise).to receive(:order).with(:id).and_return(enterprise_scope)
        allow(enterprise_scope).to receive(:last).and_return(enterprise)

        expect(sample_data.sample_enterprise).to eq(enterprise)
      end
    end

    describe "#sample_distributor" do
      it "uses the sample enterprise when one exists" do
        enterprise = double("enterprise")
        allow(sample_data).to receive(:sample_enterprise).and_return(enterprise)

        expect(sample_data.sample_distributor).to eq(enterprise)
      end

      it "falls back to the sample order distributor" do
        distributor = double("distributor")
        allow(sample_data).to receive(:sample_enterprise).and_return(nil)
        allow(sample_data).to receive(:sample_order)
          .and_return(double("order", distributor: distributor))

        expect(sample_data.sample_distributor).to eq(distributor)
      end

      it "returns nil safely when there is no sample order" do
        allow(sample_data).to receive(:sample_enterprise).and_return(nil)
        allow(sample_data).to receive(:sample_order).and_return(nil)

        expect(sample_data.sample_distributor).to be_nil
      end
    end

    describe "#sample_producer" do
      it "uses the enterprise associated with the first line item's variant" do
        producer = double("producer")
        variant = double("variant", enterprise: producer)
        line_item = double("line item", variant: variant)
        order = double("order", line_items: [line_item])
        allow(sample_data).to receive(:sample_order).and_return(order)

        expect(sample_data.sample_producer).to eq(producer)
      end

      it "falls back to the most recent enterprise when the order has no producer" do
        enterprise_scope = double("enterprises")
        producer = double("producer")
        line_item = double("line item", variant: nil)
        order = double("order", line_items: [line_item])
        allow(sample_data).to receive(:sample_order).and_return(order)
        allow(Enterprise).to receive(:order).with(:id).and_return(enterprise_scope)
        allow(enterprise_scope).to receive(:last).and_return(producer)

        expect(sample_data.sample_producer).to eq(producer)
      end

      it "safely falls back when there is no sample order" do
        enterprise_scope = double("enterprises")
        producer = double("producer")
        allow(sample_data).to receive(:sample_order).and_return(nil)
        allow(Enterprise).to receive(:order).with(:id).and_return(enterprise_scope)
        allow(enterprise_scope).to receive(:last).and_return(producer)

        expect(sample_data.sample_producer).to eq(producer)
      end
    end

    describe "#sample_order_cycle" do
      it "uses the order's order cycle when present" do
        order_cycle = double("order cycle")
        allow(sample_data).to receive(:sample_order)
          .and_return(double("order", order_cycle: order_cycle))

        expect(sample_data.sample_order_cycle).to eq(order_cycle)
      end

      it "falls back to the most recent order cycle" do
        order_cycle_scope = double("order cycles")
        order_cycle = double("order cycle")
        allow(sample_data).to receive(:sample_order).and_return(nil)
        allow(OrderCycle).to receive(:order).with(:id).and_return(order_cycle_scope)
        allow(order_cycle_scope).to receive(:last).and_return(order_cycle)

        expect(sample_data.sample_order_cycle).to eq(order_cycle)
      end
    end

    describe "#sample_payment" do
      it "uses the first payment on the sample order when present" do
        payment = double("payment")
        order = double("order", payments: [payment])
        allow(sample_data).to receive(:sample_order).and_return(order)

        expect(sample_data.sample_payment).to eq(payment)
      end

      it "falls back to the most recent payment" do
        payment_scope = double("payments")
        payment = double("payment")
        allow(sample_data).to receive(:sample_order).and_return(nil)
        allow(Spree::Payment).to receive(:order).with(:id).and_return(payment_scope)
        allow(payment_scope).to receive(:last).and_return(payment)

        expect(sample_data.sample_payment).to eq(payment)
      end
    end

    describe "#test_recipient" do
      it "returns the recipient from the loaded email configuration" do
        expect(sample_data.test_recipient).to eq("test@example.com")
      end

      it "returns nil when no recipient is configured" do
        allow(config).to receive(:load_email_config).and_return("recipient" => nil)

        expect(sample_data.test_recipient).to be_nil
      end
    end
  end
end
