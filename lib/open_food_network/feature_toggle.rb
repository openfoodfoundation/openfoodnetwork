# frozen_string_literal: true

module OpenFoodNetwork
  # Feature toggles are configured via Flipper.
  #
  # - config/initializers/flipper.rb
  # - http://localhost:3000/admin/feature-toggle/features
  #
  module FeatureToggle
    def self.conditional_features
      features = {}
      if Rails.env.development?
        features.merge!({
                          "admin_style_v3" => <<~DESC,
                            Test the work-in-progress design updates.
                          DESC
                        });
      end

      features
    end

    # Please add your new feature here to appear in the Flipper UI.
    # We way move this to a YAML file when it becomes too awkward.
    # **WARNING:** Features not in this list will be removed.
    #
    # Once the feature is ready for general production use,
    # copy the feature declaration to ACTIVE_BY_DEFAULT below and
    # activate it for all instances with a migration:
    #
    #   ./bin/rails generate migration EnableFeatureDragonMode
    #
    # Replace the `change` method with an `up` method and add this line:
    #
    #   Flipper.enable("dragon_mode")
    #
    CURRENT_FEATURES = {
      "api_reports" => <<~DESC,
        An API endpoint for reports at
        <code>/api/v0/reports/:report_type(/:report_subtype)</code>
      DESC
      "api_v1" => <<~DESC,
        Enable the new API at <code>/api/v1</code>
      DESC
      "match_shipping_categories" => <<~DESC,
        During checkout, show only shipping methods that support <em>all</em>
        shipping categories. Activating this feature for an enterprise owner
        will activate it for all shops of this enterprise.
      DESC
      "invoices" => <<~DESC,
        Preserve the state of generated invoices and enable multiple invoice numbers instead of only one live-updating invoice.
      DESC
      "connected_apps" => <<~DESC,
        Enterprise data can be shared with another app.
        The first example is the Australian Discover Regenerative Portal.
      DESC
      "affiliate_sales_data" => <<~DESC,
        Activated for a user.
        The user (INRAE researcher) has access to anonymised sales.
      DESC
      "open_in_same_tab" => <<~DESC,
        Open the admin dashboard in the same tab instead of a new tab.
      DESC
      "variant_tag" => <<~DESC,
        Variant Tag are available on the Bulk Edit Products page.
      DESC
      "inventory" => <<~DESC,
        Enable the inventory.
      DESC
    }.merge(conditional_features).freeze;

    # Features you would like to be enabled to start with.
    ACTIVE_BY_DEFAULT = {
      # Copy features here that were activated in a migration so that new
      # instances, development and test environments have the feature active.
      "admin_style_v3" => <<~DESC,
        Test the work-in-progress design updates.
      DESC
    }.freeze

    def self.setup!
      CURRENT_FEATURES.each_key do |name|
        feature = Flipper.feature(name)
        unless feature.exist?
          feature.add
          feature.enable if ACTIVE_BY_DEFAULT[name]
        end
      end

      Flipper.features.each do |feature|
        feature.remove unless CURRENT_FEATURES.key?(feature.name)
      end
    end

    # Checks weather a feature is enabled for any of the given actors.
    def self.enabled?(feature_name, *actors)
      # TODO: Need to remove these checks when we fully remove the toggle from development as well
      # need this check as Flipper won't recognize 'admin_style_v3' as it is removed for server envs
      return true if !Rails.env.development? && feature_name == :admin_style_v3
      return Flipper.enabled?(feature_name) if actors.empty?

      actors.any? do |actor|
        Flipper.enabled?(feature_name, actor)
      end
    end

    # Checks weather a feature is disabled for all given actors.
    def self.disabled?(feature_name, *actors)
      !enabled?(feature_name, *actors)
    end
  end
end
