require "chili"
require "eaterprises_feature/engine"

module EaterprisesFeature
  extend Chili::Base
  active_if { ENV['OFW_DEPLOYMENT'] == 'eaterprises' }
end
