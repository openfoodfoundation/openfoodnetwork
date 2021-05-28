# frozen_string_literal: false

module SubsLogger
  class Formatter < ::Logger::Formatter
    def call(_severity, timestamp, _progname, msg)
      time = timestamp.strftime('%FT%T%z')
      "#{time}: #{msg.is_a?(String) ? msg : msg.inspect}\n"
    end
  end

  def self.logger
    @logger ||= begin
                  logger = ActiveSupport::Logger.new(Rails.root.join('log', 'subscriptions.log'))
                  logger.formatter = Formatter.new
                  logger
                end
  end
end
