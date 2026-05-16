# frozen_string_literal: true

require Rails.root.join("lib/tasks/test_emails/fake_blob")
require Rails.root.join("lib/tasks/test_emails/fake_subscription_summary")
require Rails.root.join("lib/tasks/test_emails/helpers")

namespace :test do
  include EmailTestHelpers

  ENV["GTK_MODULES"] = ""
  ENV["G_MESSAGES_DEBUG"] = ""

  desc "Send configured emails for layout testing"

  task send_emails: :environment do
    run_email_test_suite
  end

  def run_email_test_suite
    print_header("Starting Email Layout Test Suite")

    mailers = load_mailers

    return puts "❌ No mailers found!" if mailers.empty?

    prepare_test_data

    config = configure_emails(mailers)

    send_configured_emails(mailers, config)
  end

  def prepare_test_data
    puts "\nGathering test data..."

    gather_test_data
  rescue StandardError => e
    puts "❌ Error gathering test data: #{e.message}"
    puts e.backtrace.first(10).join("\n")

    exit 1
  end

  def send_configured_emails(mailers, config)
    puts "\nSending test emails...\n"

    email_config = config.fetch("emails", {})

    total_sent = 0
    errors = 0

    mailers.each do |mailer_class|
      get_mailer_actions(mailer_class).each do |action|
        key = "#{mailer_class}##{action}"

        next unless email_config[key]

        total_sent, errors =
          process_email(
            mailer_class,
            action,
            total_sent,
            errors
          )
      end
    end

    print_footer(total_sent, errors)
  end

  def process_email(mailer_class, action, total_sent, errors)
    key = "#{mailer_class}##{action}"

    send_test_email(mailer_class, action)

    puts "✓ #{key}"

    [total_sent + 1, errors]
  rescue StandardError => e
    puts "❌ #{key}: #{e.message}"

    [total_sent, errors + 1]
  end
end
