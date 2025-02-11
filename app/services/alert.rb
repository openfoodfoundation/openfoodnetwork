# frozen_string_literal: true

# A handy wrapper around error reporting libraries like Bugsnag.
#
# Bugsnag's API is great for general purpose but overly complex for our use.
# It also changes over time and we often make mistakes using it. So this class
# aims at:
#
# * Abstracting from Bugsnag, open for other services.
# * Simpler interface to reduce user error.
# * Central place to update Bugsnag API usage when it changes.
#
class Alert
  # Alert Bugsnag with additional metadata to appear in tabs.
  #
  #   Alert.raise(
  #     "Invalid order during checkout",
  #     {
  #       order: { number: "ABC123", state: "awaiting_return" },
  #       env: { referer: "example.com" }
  #     }
  #   )
  def self.raise(error, metadata = {}, &block)
    Bugsnag.notify(error) do |payload|
      unless metadata.respond_to?(:each)
        metadata = { metadata: { data: metadata } }
      end

      metadata.each do |name, data|
        # Bugsnag only reports metadata when given a Hash.
        data = { data: } unless data.is_a?(Hash)
        payload.add_metadata(name, data)
      end

      block.call(payload)
    end
  end

  def self.raise_with_record(error, record, &)
    metadata = {
      record.class.name => record&.attributes || { record_was_nil: true }
    }
    self.raise(error, metadata, &)
  end
end
