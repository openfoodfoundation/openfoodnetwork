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
    # **WARNING:** Features not in this list will be removed.
    CURRENT_FEATURES = {
      "admin_style_v3" => <<~DESC,
        Test the work-in-progress design updates.
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
      "match_shipping_categories" => <<~DESC,
        During checkout, show only shipping methods that support <em>all</em>
        shipping categories. Activating this feature for an enterprise owner
        will activate it for all shops of this enterprise.
      DESC
      "vouchers" => <<~DESC,
        Add voucher functionality. Voucher can be managed via Enterprise settings.
      DESC
      "invoices" => <<~DESC,
        Preserve the state of generated invoices and enable multiple invoice numbers instead of only one live-updating invoice.
      DESC
    }.freeze

    def self.setup!
      CURRENT_FEATURES.each_key do |name|
        feature = Flipper.feature(name)
        feature.add unless feature.exist?
      end

      Flipper.features.each do |feature|
        feature.remove unless CURRENT_FEATURES.key?(feature.name)
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
