require 'open_food_network/feature'
require 'open_food_network/null_feature'
require 'open_food_network/ga_feature'

module OpenFoodNetwork
  # This feature toggles implementation provides two mechanisms to conditionally enable features.
  #
  # You can provide an ENV var with the prefix `OFN_FEATURE_` and query it using the
  # `ApplicationHelper#feature?` helper method. For instance, providing the ENV var
  # `OFN_FEATURE_NEW_SHINNY_FEATURE` you could then query it from view as follows:
  #
  #   - if feature? :new_shiny_feature
  #     = render "new_shiny_feature"
  #
  # Alternatively, you can choose which users have the feature toggled on. To do that you need to
  # register the feature and its users using `.enable` like:
  #
  #   OpenFoodNetwork::FeatureToggle.enable(:new_shiny_feature, ['ofn@example.com'])
  #
  # This is handled in config/initializers/feature_toggles.rb.
  #
  # There's also the option to toggle something on for everyone using "all" instead of an email:
  #
  #   OpenFoodNetwork::FeatureToggle.enable(:new_shiny_feature, ['all'])
  #
  # This doesn't require a deployment but to change the ENV var and restart Unicorn and DJ.
  #
  # You can then check it from a view like:
  #
  #   - if feature? :new_shiny_feature, spree_current_user
  #     = render "new_shiny_feature"
  #
  class FeatureToggle
    def self.enabled?(feature_name, user = nil)
      new.enabled?(feature_name, user)
    end

    def self.enable(feature_name, user_emails)
      return unless user_emails.present?

      Thread.current[:features] ||= {}

      klass = user_emails == ["all"] ? GAFeature : Feature
      Thread.current[:features][feature_name] = klass.new(user_emails)
    end

    def initialize
      @features = Thread.current[:features] || {}
    end

    def enabled?(feature_name, user)
      if user.present?
        feature = features.fetch(feature_name, NullFeature.new)
        feature.enabled?(user)
      else
        true?(env_variable_value(feature_name))
      end
    end

    private

    attr_reader :features

    def env_variable_value(feature_name)
      ENV.fetch(env_variable_name(feature_name), nil)
    end

    def env_variable_name(feature_name)
      "OFN_FEATURE_#{feature_name.to_s.upcase}"
    end

    def true?(value)
      value.to_s.casecmp("true").zero?
    end
  end
end
