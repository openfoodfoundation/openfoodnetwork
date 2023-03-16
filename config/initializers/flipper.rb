require "flipper"
require "flipper/adapters/active_record"

if Rails.env.production?
  Flipper::UI.configure do |config|
    config.banner_text = '⚠️ Production environment: be aware that the changes have an impact on the application. Please, read the how-to before: https://github.com/openfoodfoundation/openfoodnetwork/wiki/Feature-toggle-with-Flipper'
    config.banner_class = 'danger'
  end
end

Flipper.register(:admins) { |actor| actor.respond_to?(:admin?) && actor.admin? }
