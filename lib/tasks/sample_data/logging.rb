module Logging
  private

  def log(message)
    @logger ||= ActiveSupport::TaggedLogging.new(Logger.new(STDOUT))
    @logger.tagged("openfoodnetwork:sample_data:load") { @logger.info(message) }
  end
end
