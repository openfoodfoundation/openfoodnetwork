require "chili"
require "eaterprises_feature/engine"

module EaterprisesFeature
  extend Chili::Base
  active_if { OpenFoodNetwork::FeatureToggle.enabled? :eaterprises }
end
