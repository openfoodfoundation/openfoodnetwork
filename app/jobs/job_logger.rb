# frozen_string_literal: false

module JobLogger
  class Formatter < ::Logger::Formatter
    def call(_severity, timestamp, _progname, msg)
      time = timestamp.strftime('%FT%T%z')
      "#{time}: #{msg.is_a?(String) ? msg : msg.inspect}\n"
    end
  end

  def self.logger
    @logger ||= begin
      logger = Rails.logger.clone
      logger.formatter = Formatter.new
      logger
    end
  end
end
