# frozen_string_literal: true

# rubocop:disable Metrics/ModuleLength

require "yaml"

module EmailTestHelpers
  CONFIG_PATH = Rails.root.join("tmp/email_test_config.yml")

  DEFAULT_CONFIG = {
    "recipient" => nil,
    "emails" => {},
  }.freeze

  TEST_DATA = {
    user: -> { @user },
    address: -> { @address },
    order: -> { @order },
    shipment: -> { @shipment },
    payment: -> { @payment },
    distributor: -> { @distributor },
    enterprise: -> { @distributor },
    order_cycle: -> { @order_cycle },
    producer: -> { @producer },

    token: -> { "test_token" },
    changes: -> { {} },
    amount: -> { 10.0 },

    url: -> { "http://example.com/status" },
    taler_order_status_url: -> { "http://example.com/status" },

    order_id: -> { @order.id },
    order_or_order_id: -> { @order },

    opts: -> { {} },
    _opts: -> { {} },
    options: -> { {} }
  }.freeze

  FALLBACK_MATCHERS = {
    /user/ => :user,
    /order/ => :order,
    /shipment/ => :shipment,
    /payment/ => :payment,
    /token/ => :token,
    /enterprise/ => :enterprise,
    /producer/ => :producer,
    /distributor/ => :distributor,
    /order_cycle/ => :order_cycle,
    /url/ => :url
  }.freeze

  SPECIAL_MAILERS = {
    "Spree::ShipmentMailer#shipped_email" => lambda { |mailer_class, action|
      mailer_class.public_send(
        action,
        @shipment,
        delivery: true
      ).deliver_now
    },

    "ReportMailer#report_ready" => lambda { |mailer_class, action|
      mailer_class
        .with(
          to: @user.email,
          subject: "Test Report Ready",
          blob: FakeBlob.new
        )
        .public_send(action)
        .deliver_now
    },

    "SubscriptionMailer#placement_summary_email" => lambda { |mailer_class, action|
      send_summary_email(
        mailer_class,
        action,
        :placement
      )
    },

    "SubscriptionMailer#confirmation_summary_email" => lambda { |mailer_class, action|
      send_summary_email(
        mailer_class,
        action,
        :confirmation
      )
    }
  }.freeze

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

    input = $stdin.gets.chomp.strip

    return config if input.empty?

    config.merge("recipient" => input)
  end

  def configure_emails(mailers)
    config = load_email_config

    config = configure_recipient(config)

    email_config = config.fetch("emails", {})

    email_keys = display_available_emails(mailers, email_config)

    print_selection_help

    input = $stdin.gets.chomp.strip

    return config.tap { save_email_config(config) } if input.empty?

    selected_indexes = parse_selection_input(input, email_keys.size)

    config["emails"] =
      build_email_config(email_keys, selected_indexes)

    save_email_config(config)

    config
  end

  def display_available_emails(mailers, email_config)
    $stdout.puts("\nAvailable emails:\n")

    index = 1
    email_keys = []

    mailers.each do |mailer_class|
      get_mailer_actions(mailer_class).each do |action|
        key = "#{mailer_class}##{action}"

        marker = email_config.fetch(key, false) ? "x" : " "

        $stdout.puts(format("%2d. [%s] %s", index, marker, key))

        email_keys << key
        index += 1
      end
    end

    email_keys
  end

  def deliver_mail(mailer_class, action, positional_args, keyword_args)
    mail =
      if keyword_args.any?
        mailer_class.public_send(
          action,
          *positional_args,
          **keyword_args
        )
      else
        mailer_class.public_send(
          action,
          *positional_args
        )
      end

    override_recipient(mail)

    mail.deliver_now
  end

  def append_mailer_actions(email_keys, mailer_class, config)
    get_mailer_actions(mailer_class).each do |action|
      index = email_keys.size + 1
      key = "#{mailer_class}##{action}"

      marker = config.fetch(key, false) ? "x" : " "

      $stdout.puts format("%2d. [%s] %s", index, marker, key)

      email_keys << key
    end
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

  def load_mailers
    Rails.root.glob("app/mailers/**/*_mailer.rb")
      .reject { |file| file.to_s.end_with?("application_mailer.rb") }
      .filter_map { |file| load_mailer(file) }
      .uniq
  end

  def load_mailer(file)
    relative =
      file
        .relative_path_from(Rails.root.join("app/mailers"))
        .to_s

    class_name =
      relative
        .delete_suffix(".rb")
        .camelize

    klass = class_name.constantize

    return unless klass < ApplicationMailer

    $stdout.puts "✓ Loaded #{class_name}"

    klass
  rescue StandardError => e
    $stdout.puts "⚠ Warning: Could not load #{class_name}: #{e.message}"

    nil
  end

  def get_mailer_actions(mailer_class)
    mailer_class.public_instance_methods(false)
      .map(&:to_s)
      .reject do |method|
        method.start_with?("_") || method == "mail"
      end
      .sort
  end

  def gather_test_data
    @user = find_first!(Spree::User, "users")
    @address = find_first!(Spree::Address, "addresses")
    @shipment = find_first!(Spree::Shipment, "shipments")
    @payment = find_first!(Spree::Payment, "payments")

    load_order_data

    $stdout.puts "✓ Real email test data ready"
  end

  def load_order_data
    @order =
      Spree::Order.complete
        .includes(:line_items)
        .find { |order| order.line_items.any? }

    raise "No completed order with line items found" unless @order

    @distributor = @order.distributor
    @order_cycle = @order.order_cycle
    @producer = @order.line_items.first.variant.supplier
  end

  def find_first!(klass, name)
    klass.first || raise("No #{name} found")
  end

  def send_test_email(mailer_class, action)
    key = "#{mailer_class}##{action}"

    special_handler = SPECIAL_MAILERS[key]

    return instance_exec(mailer_class, action, &special_handler) if special_handler

    send_dynamic_email(mailer_class, action)
  end

  def send_dynamic_email(mailer_class, action)
    method = mailer_class.instance_method(action)

    positional_args, keyword_args =
      build_mail_arguments(method)

    deliver_mail(
      mailer_class,
      action,
      positional_args,
      keyword_args
    )
  end

  def build_mail_arguments(method)
    positional_args = []
    keyword_args = {}

    build_arguments(method).each do |type, name, value|
      if keyword_argument?(type)
        keyword_args[name] = value
      else
        positional_args << value
      end
    end

    [positional_args, keyword_args]
  end

  def build_arguments(method)
    method.parameters.map do |type, name|
      value = argument_value(type, name)

      raise "No test data configured for :#{name}" if value == :__missing__

      [type, name, value]
    end
  end

  def argument_value(type, name)
    provider = provider_for(name)

    return instance_exec(&provider) if provider

    default_value_for(type, name)
  end

  def provider_for(name)
    TEST_DATA[name] || fallback_provider(name)
  end

  def fallback_provider(name)
    matched_key =
      FALLBACK_MATCHERS.find do |matcher, _key|
        matcher.match?(name.to_s)
      end&.last

    TEST_DATA[matched_key] if matched_key
  end

  def default_value_for(type, name)
    return :__missing__ unless [:opt, :key].include?(type)

    optional_default(name)
  end

  def optional_default(name)
    return false if name.to_s.match?(/resend/)

    return {} if name.to_s.match?(/options?|opts?|params?/)

    nil
  end

  def keyword_argument?(type)
    [:keyreq, :key].include?(type)
  end

  def send_summary_email(mailer_class, action, type)
    summary = FakeSubscriptionSummary.new(
      shop_id: @distributor.id,
      type: type,
      orders: [@order]
    )

    mailer_class.public_send(action, summary).deliver_now
  end

  def override_recipient(mail)
    recipient = load_email_config["recipient"]

    return if recipient.blank?

    mail.to = [recipient]
    mail.cc = nil
    mail.bcc = nil
  end

  def print_header(title)
    divider = "=" * 60

    $stdout.puts "\n#{divider}"
    $stdout.puts title
    $stdout.puts divider
  end

  def print_footer(total_sent, errors)
    divider = "=" * 60

    $stdout.puts "\n#{divider}"
    $stdout.puts "Email Test Suite Complete"
    $stdout.puts "Total emails sent: #{total_sent}"
    $stdout.puts "Errors encountered: #{errors}"
    $stdout.puts "#{divider}\n"
  end
end

# rubocop:enable Metrics/ModuleLength
