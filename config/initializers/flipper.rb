require "flipper"
require "flipper/adapters/active_record"

Flipper.configure do |config|
  config.default do
    Flipper.new(Flipper::Adapters::ActiveRecord.new)
  end
end
Rails.configuration.middleware.use Flipper::Middleware::Memoizer, preload_all: true

Flipper.register(:admins) { |actor| actor.respond_to?(:admin?) && actor.admin? }

if !Flipper[:unit_price].exist?
  # Unit price default setup, could be overided by admin in the flipper-ui interface
  Flipper.enable_group :unit_price, :admins
end
