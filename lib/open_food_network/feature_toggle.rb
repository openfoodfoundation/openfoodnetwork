module OpenFoodNetwork
  # This feature toggles implementation provides two mechanisms to conditionally enable features.
  #
  # You can configure features via the Flipper config and web interface. See:
  #
  # - config/initializers/flipper.rb
  # - http://localhost:3000/admin/feature-toggle/features
  #
  # Alternatively, you can choose which users have the feature toggled on. To do that you need to
  # register the feature and its users from an initializer like:
  #
  #   require 'open_food_network/feature_toggle'
  #   OpenFoodNetwork::FeatureToggle.enable(:new_shiny_feature, ['ofn@example.com'])
  #
  # Note, however, that it'd be better to read the user emails from an ENV var provisioned with
  # ofn-install:
  #
  #   require 'open_food_network/feature_toggle'
  #   OpenFoodNetwork::FeatureToggle.enable(:new_shiny_feature, ENV['PRODUCT_TEAM'])
  #
  # You can then check it from a view like:
  #
  #   - if feature? :new_shiny_feature, spree_current_user
  #     = render "new_shiny_feature"
  #
  module FeatureToggle
    def self.enabled?(feature_name, user = nil)
      features = Thread.current[:features] || {}

      if Flipper[feature_name].exist?
        Flipper.enabled?(feature_name, user)
      else
        feature = features.fetch(feature_name, DefaultFeature.new)
        feature.enabled?(user)
      end
    end

    def self.enable(feature_name, &block)
      Thread.current[:features] ||= {}
      Thread.current[:features][feature_name] = Feature.new(block)
    end
  end

  class Feature
    def initialize(block)
      @block = block
    end

    def enabled?(user)
      block.call(user)
    end

    private

    attr_reader :block
  end

  class DefaultFeature
    def enabled?(_user)
      false
    end
  end
end
