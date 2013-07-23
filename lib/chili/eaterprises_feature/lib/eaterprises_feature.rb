require "chili"
require "eaterprises_feature/engine"

module EaterprisesFeature
  extend Chili::Base
  active_if { OpenFoodWeb::FeatureToggle.enabled? :eaterprises }
end
