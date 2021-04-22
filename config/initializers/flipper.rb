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

if Rails.env.production?
  Flipper::UI.configure do |config|
    config.banner_text = '⚠️ Production environment: be aware that the changes have an impact on the application. Please, read the how-to before: https://github.com/openfoodfoundation/openfoodnetwork/wiki/Feature-toggle-with-Flipper'
    config.banner_class = 'danger'
  end
end

Rails.configuration.middleware.use Flipper::Middleware::Memoizer, preload_all: true

Flipper.register(:admins) { |actor| actor.respond_to?(:admin?) && actor.admin? }
