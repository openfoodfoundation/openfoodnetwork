# frozen_string_literal: true

module OpenFoodNetwork
  # Feature toggles are configured via Flipper.
  #
  # - config/initializers/flipper.rb
  # - http://localhost:3000/admin/feature-toggle/features
  #
  module FeatureToggle
    # Please add your new feature here to appear in the Flipper UI.
    # We way move this to a YAML file when it becomes too awkward.
    CURRENT_FEATURES = {
      "admin_style_v2" => <<~DESC,
        Change some colour and layout in the backend to a newer version.
      DESC
      "api_reports" => <<~DESC,
        An API endpoint for reports at
        <code>/api/v0/reports/:report_type(/:report_subtype)</code>
      DESC
      "api_v1" => <<~DESC,
        Enable the new API at <code>/api/v1</code>
      DESC
      "background_reports" => <<~DESC,
        Generate reports in a background process to limit memory consumption.
      DESC
      "dfc_provider" => <<~DESC,
        Enable the DFC compatible endpoint at <code>/api/dfc-*</code>.
      DESC
      "match_shipping_categories" => <<~DESC,
        During checkout, show only shipping methods that support <em>all</em>
        shipping categories. Activating this feature for an enterprise owner
        will activate it for all shops of this enterprise.
      DESC
      "new_products_page" => <<~DESC,
        Show the new (experimental) version of the admin products page.
      DESC
      "split_checkout" => <<~DESC,
        Replace the one-page checkout with a multi-step checkout.
      DESC
    }.freeze

    # Move your feature entry from CURRENT_FEATURES to RETIRED_FEATURES when
    # you remove it from the code. It will then be deleted from the database.
    #
    # We may delete this field one day and regard all features not listed in
    # CURRENT_FEATURES as unsupported and remove them. But until this approach
    # is accepted we delete only the features listed here.
    RETIRED_FEATURES = {}.freeze

    def self.setup!
      CURRENT_FEATURES.each_key do |name|
        feature = Flipper.feature(name)
        feature.add unless feature.exist?
      end

      RETIRED_FEATURES.each_key do |name|
        feature = Flipper.feature(name)
        feature.remove if feature.exist?
      end
    end

    def self.enabled?(feature_name, user = nil)
      Flipper.enabled?(feature_name, user)
    end

    def self.disabled?(feature_name, user = nil)
      !enabled?(feature_name, user)
    end
  end
end
