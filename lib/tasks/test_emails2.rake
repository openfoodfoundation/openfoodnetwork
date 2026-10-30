# frozen_string_literal: true

namespace :ofn do
  ENV["GTK_MODULES"] = ""
  ENV["G_MESSAGES_DEBUG"] = ""

  desc "Send representative emails using the sample data created by `ofn:sample_data`"
  task test_emails: :environment do
    ensure_sample_data!

    EmailTestData.new.run
  end

  def ensure_sample_data!
    return if Spree::Order.any? && Enterprise.any?

    Rake::Task["ofn:sample_data"].invoke
  end

  def print_header(title)
    divider = "=" * 60

    $stdout.puts "\n#{divider}"
    $stdout.puts title
    $stdout.puts divider
  end
end

class EmailTestData
  EMAIL_KEYS = [
    "BackorderMailer#backorder_failed",
    "BackorderMailer#backorder_incomplete",
    "EnterpriseMailer#manager_invitation",
    "EnterpriseMailer#welcome",
    "PaymentMailer#authorization_required",
    "PaymentMailer#authorize_payment",
    "PaymentMailer#refund_available",
    "ProducerMailer#order_cycle_report",
    "ReportMailer#report_ready",
    "Spree::OrderMailer#cancel_email",
    "Spree::OrderMailer#cancel_email_for_shop",
    "Spree::OrderMailer#confirm_email_for_customer",
    "Spree::OrderMailer#confirm_email_for_shop",
    "Spree::OrderMailer#invoice_email",
    "Spree::ShipmentMailer#shipped_email_delivery",
    "Spree::ShipmentMailer#shipped_email_pickup",
    "Spree::TestMailer#test_email",
    "Spree::UserMailer#confirmation_instructions",
    "Spree::UserMailer#reset_password_instructions",
    "Spree::UserMailer#signup_confirmation",
    "SubscriptionMailer#confirmation_email",
    "SubscriptionMailer#confirmation_summary_email",
    "SubscriptionMailer#empty_email",
    "SubscriptionMailer#failed_payment_email",
    "SubscriptionMailer#placement_email",
    "SubscriptionMailer#placement_summary_email"
  ].freeze

  def run
    print_header("Starting Email Layout Test Suite")

    configuration = Configuration.new
    config = configuration.load_email_config
    config = configuration.configure_recipient(config)

    email_keys = configuration.display_available_emails

    configuration.print_selection_help
    input = $stdin.gets.to_s.strip

    if input.present?
      selected_indexes = configuration.parse_selection_input(input, email_keys.size)
      config["emails"] = configuration.build_email_config(email_keys, selected_indexes)
    else
      config["emails"] = config.fetch("emails", {}).presence ||
                         configuration.build_email_config(email_keys, (1..email_keys.size).to_a)
    end

    configuration.save_email_config(config)
    send_selected_emails(config["emails"])
  end

  def send_selected_emails(email_config)
    EMAIL_KEYS.each do |key|
      next unless email_config[key]

      begin
        EmailSender.new(self).send_email_for(key)
        puts "✓ #{key}"
      rescue StandardError => e
        puts "❌ #{key}: #{e.class} - #{e.message}"
      end
    end
  end

  def load_email_config
    Configuration.new.load_email_config
  end

  def sample_data
    @sample_data ||= SampleData.new(self)
  end

  %i[
    sample_order sample_shipment sample_user sample_enterprise sample_distributor
    sample_producer sample_order_cycle sample_payment test_recipient subscription_summary
  ].each do |method|
    define_method(method) { sample_data.public_send(method) }
  end

  class Configuration
    CONFIG_PATH = Rails.root.join("tmp/email_test_config.yml")
    DEFAULT_CONFIG = {
      "recipient" => nil,
      "emails" => {}
    }.freeze

    EMAIL_KEYS = EmailTestData::EMAIL_KEYS

    def load_email_config
      return DEFAULT_CONFIG.deep_dup unless File.exist?(CONFIG_PATH)

      DEFAULT_CONFIG.deep_merge(YAML.load_file(CONFIG_PATH) || {})
    end

    def save_email_config(config)
      File.write(CONFIG_PATH, config.to_yaml)
    end

    def configure_recipient(config)
      current_recipient = config["recipient"]

      $stdout.puts("\nMake sure to enter an email address you have access to!")
      $stdout.puts(
        if current_recipient.present?
          "Current recipient: #{current_recipient}"
        else
          "Currently no recipient configured."
        end
      )

      $stdout.print("Enter recipient email (empty keeps current): ")

      input = $stdin.gets.to_s.strip
      return config if input.empty?

      config.merge("recipient" => input)
    end

    def display_available_emails
      $stdout.puts("\nAvailable emails:\n")

      config = load_email_config
      email_keys = []

      EMAIL_KEYS.each_with_index do |key, index|
        marker = config.fetch("emails", {}).fetch(key, false) ? "x" : " "
        $stdout.puts(format("%2d. [%s] %s", index + 1, marker, key))
        email_keys << key
      end

      email_keys
    end

    def print_selection_help
      $stdout.puts
      $stdout.puts "Examples:"
      $stdout.puts "  1,4,7"
      $stdout.puts "  1-5"
      $stdout.puts "  all"
      $stdout.puts "  empty input keeps current selection"
      $stdout.puts
      $stdout.print "Select emails to send: "
    end

    def parse_selection_input(input, total)
      return (1..total).to_a if input.downcase == "all"

      input.split(",").flat_map do |part|
        parse_selection_part(part.strip)
      end
    end

    def parse_selection_part(part)
      return part.to_i unless part.include?("-")

      from, to = part.split("-").map(&:to_i)
      (from..to).to_a
    end

    def build_email_config(email_keys, selected_indexes)
      config = email_keys.index_with(false)

      selected_indexes.each do |index|
        key = email_keys[index - 1]
        config[key] = true if key
      end

      config
    end
  end

  module EmailSenderHelpers
    def self.backorder_incomplete(data)
      order = data.sample_order
      distributor = order.distributor
      user = distributor&.owner
      order_cycle = order.order_cycle
      return if distributor.blank? || user.blank? || order_cycle.blank?

      BackorderMailer.backorder_incomplete(
        user,
        distributor,
        order_cycle,
        "https://example.org/api/dfc/Enterprises/#{distributor.permalink}/Orders/#{order.id}"
      )
    end

    def self.report_ready(data)
      report_blob = ReportBlob.last || ReportBlob.create_locally!("sample_report.csv",
                                                                  "sample report")
      ReportMailer.with(to: data.test_recipient, blob: report_blob).report_ready
    end
  end

  class EmailSender
    def initialize(data)
      @data = data
    end

    def send_email_for(key)
      sender = SENDERS[key]
      raise "No sender defined for #{key}" unless sender

      mail = sender.call(@data)
      return unless mail

      recipient = @data.test_recipient
      raise "No test recipient configured!" if recipient.blank?

      mail.message.to = recipient
      mail.deliver_now
    end

    SENDERS = {
      "BackorderMailer#backorder_failed" => ->(d) {
        BackorderMailer.backorder_failed(d.sample_order)
      },
      "BackorderMailer#backorder_incomplete" => ->(d) {
        EmailSenderHelpers.backorder_incomplete(d)
      },
      "EnterpriseMailer#manager_invitation" => ->(d) {
        EnterpriseMailer.manager_invitation(d.sample_enterprise, d.sample_user)
      },
      "EnterpriseMailer#welcome" => ->(d) { EnterpriseMailer.welcome(d.sample_enterprise) },
      "PaymentMailer#authorization_required" => ->(d) {
        PaymentMailer.authorization_required(d.sample_payment)
      },
      "PaymentMailer#authorize_payment" => ->(d) {
        PaymentMailer.authorize_payment(d.sample_payment)
      },
      "PaymentMailer#refund_available" => ->(d) {
        PaymentMailer.refund_available(10.0, d.sample_payment, "http://example.com/status")
      },
      "ProducerMailer#order_cycle_report" => ->(d) {
        ProducerMailer.order_cycle_report(d.sample_producer, d.sample_order_cycle)
      },
      "ReportMailer#report_ready" => ->(d) { EmailSenderHelpers.report_ready(d) },
      "Spree::OrderMailer#cancel_email" => ->(d) {
        Spree::OrderMailer.cancel_email(d.sample_order)
      },
      "Spree::OrderMailer#cancel_email_for_shop" => ->(d) {
        Spree::OrderMailer.cancel_email_for_shop(d.sample_order)
      },
      "Spree::OrderMailer#confirm_email_for_customer" => ->(d) {
        Spree::OrderMailer.confirm_email_for_customer(d.sample_order)
      },
      "Spree::OrderMailer#confirm_email_for_shop" => ->(d) {
        Spree::OrderMailer.confirm_email_for_shop(d.sample_order)
      },
      "Spree::OrderMailer#invoice_email" => ->(d) {
        Spree::OrderMailer.invoice_email(d.sample_order)
      },
      "Spree::ShipmentMailer#shipped_email_delivery" => ->(d) {
        Spree::ShipmentMailer.shipped_email(d.sample_shipment, delivery: true)
      },
      "Spree::ShipmentMailer#shipped_email_pickup" => ->(d) {
        Spree::ShipmentMailer.shipped_email(d.sample_shipment, delivery: false)
      },
      "Spree::TestMailer#test_email" => ->(d) { Spree::TestMailer.test_email(d.sample_user) },
      "Spree::UserMailer#confirmation_instructions" => ->(d) {
        Spree::UserMailer.confirmation_instructions(d.sample_user, "test_token")
      },
      "Spree::UserMailer#reset_password_instructions" => ->(d) {
        Spree::UserMailer.reset_password_instructions(d.sample_user, "test_token")
      },
      "Spree::UserMailer#signup_confirmation" => ->(d) {
        Spree::UserMailer.signup_confirmation(d.sample_user)
      },
      "SubscriptionMailer#confirmation_email" => ->(d) {
        SubscriptionMailer.confirmation_email(d.sample_order)
      },
      "SubscriptionMailer#confirmation_summary_email" => ->(d) {
        SubscriptionMailer.confirmation_summary_email(d.subscription_summary)
      },
      "SubscriptionMailer#empty_email" => ->(d) {
        SubscriptionMailer.empty_email(d.sample_order, [])
      },
      "SubscriptionMailer#failed_payment_email" => ->(d) {
        SubscriptionMailer.failed_payment_email(d.sample_order)
      },
      "SubscriptionMailer#placement_email" => ->(d) {
        SubscriptionMailer.placement_email(d.sample_order, [])
      },
      "SubscriptionMailer#placement_summary_email" => ->(d) {
        SubscriptionMailer.placement_summary_email(d.subscription_summary)
      }
    }.freeze
  end

  class SampleData
    def initialize(config)
      @config = config
    end

    def subscription_summary
      summary = OrderManagement::Subscriptions::Summary.new(sample_distributor.id)
      summary.record_order(sample_order)
      summary.record_success(sample_order)
      summary
    end

    def sample_order
      @sample_order ||= Spree::Order.complete.includes(:line_items).find do |order|
        order.line_items.any?
      end || Spree::Order.order(:id).last
    end

    def sample_shipment
      @sample_shipment ||= Spree::Shipment.includes(:order).order(:id).last
    end

    def sample_user
      @sample_user ||= Spree::User.order(:id).last || Spree::User.first || sample_order.user
    end

    def sample_enterprise
      @sample_enterprise ||= sample_order.distributor || Enterprise.order(:id).last
    end

    def sample_distributor
      @sample_distributor ||= sample_enterprise || sample_order&.distributor
    end

    def sample_producer
      @sample_producer ||= begin
        line_item = sample_order&.line_items&.first
        line_item&.variant&.enterprise || Enterprise.order(:id).last
      end
    end

    def sample_order_cycle
      @sample_order_cycle ||= sample_order&.order_cycle || OrderCycle.order(:id).last
    end

    def sample_payment
      @sample_payment ||= sample_order&.payments&.first || Spree::Payment.order(:id).last
    end

    def test_recipient
      @test_recipient ||= begin
        config = @config.load_email_config
        config["recipient"].presence
      end
    end
  end
end
