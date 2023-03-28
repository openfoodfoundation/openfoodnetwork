require "flipper"
require "flipper/adapters/active_record"
require "open_food_network/feature_toggle"

Flipper.register(:admins) { |actor| actor.respond_to?(:admin?) && actor.admin? }

Flipper::UI.configure do |config|
  config.descriptions_source = ->(_keys) do
    # return has to be hash of {String key => String description}
    OpenFoodNetwork::FeatureToggle::CURRENT_FEATURES
  end

  # Defaults to false. Set to true to show feature descriptions on the list
  # page as well as the view page.
  # config.show_feature_description_in_list = true

  if Rails.env.production?
    config.banner_text = <<~TEXT
      ⚠️ Production environment: be aware that the changes have an impact on the
      application. Please read the how-to before:
      https://github.com/openfoodfoundation/openfoodnetwork/wiki/Feature-toggles
    TEXT
    config.banner_class = 'danger'
  end
end

# Add known feature toggles. This may fail if the database isn't setup yet.
OpenFoodNetwork::FeatureToggle.setup! rescue ActiveRecord::StatementInvalid
