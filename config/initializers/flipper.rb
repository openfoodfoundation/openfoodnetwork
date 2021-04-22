require "flipper"
require "flipper/adapters/active_record"
require "flipper/instrumentation/log_subscriber"

Flipper.configure do |config|
  config.default do
    adapter = Flipper::Adapters::ActiveRecord.new
    instrumented = Flipper::Adapters::Instrumented.new(adapter, instrumenter: ActiveSupport::Notifications)
    Flipper.new(instrumented, instrumenter: ActiveSupport::Notifications)
  end
end
Rails.configuration.middleware.use Flipper::Middleware::Memoizer, preload_all: true

Flipper.register(:admins) { |actor| actor.respond_to?(:admin?) && actor.admin? }
