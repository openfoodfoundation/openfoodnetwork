require "chili"
require "local_organics_feature/engine"

module LocalOrganicsFeature
  extend Chili::Base
  active_if { OpenFoodWeb::FeatureToggle.enabled? :local_organics }
end
