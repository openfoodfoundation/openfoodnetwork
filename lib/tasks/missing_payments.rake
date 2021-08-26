# frozen_string_literal: true

# Find gaps in the sequence of payment ids.
# If there are gaps then see if there is a log entry with a payment result for
# the now lost payment. If there are some then you probably want to follow up
# with the affected enterprise and see if customers need to be refunded.
#
# ## Usage

# Report of the last 35 days:
#   rake ofn:missing_payments[35]
namespace :ofn do
  desc 'Find payments that got lost'
  task :missing_payments, [:days] => :environment do |_task_, args|
    days = args[:days]&.to_i || 7
    payments_sequence = Spree::Payment.where("created_at > ?", days.days.ago).order(:id).pluck(:id)
    missing_payment_ids = payments_range(payments_sequence) - payments_sequence
    puts "Gaps in the payments sequence: #{missing_payment_ids.count}"
    log_entries = Spree::LogEntry.where(
      source_type: "Spree::Payment",
      source_id: missing_payment_ids
    )
    print_csv(log_entries) if log_entries.present?
  end

  def payments_range(payments_sequence)
    if payments_sequence.empty?
      []
    else
      (payments_sequence.first..payments_sequence.last).to_a
    end
  end

  def print_csv(log_entries)
    CSV do |out|
      out << headers
      log_entries.each do |entry|
        add_row(entry, out)
      end
    end
  end

  def add_row(entry, out)
    details = Psych.load(entry.details)
    out << row(details, details.params)
  rescue StandardError
    Logger.new(STDERR).warn(entry)
  end

  def headers
    [
      "Created", "Order", "Success", "Message", "Payment ID", "Action",
      "Amount", "Currencty", "Receipt"
    ]
  end

  def row(details, params)
    [
      Time.zone.at(params["created"] || 0).to_datetime,
      params["description"],
      details.success?,
      details.message,
      params["id"],
      params["object"],
      params["amount"], params["currency"], params["receipt_url"]
    ]
  end
end
