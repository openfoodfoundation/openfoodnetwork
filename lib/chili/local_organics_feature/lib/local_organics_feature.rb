require "chili"
require "local_organics_feature/engine"

module LocalOrganicsFeature
  extend Chili::Base
  active_if { ENV['OFW_DEPLOYMENT'] == 'local_organics' }
end
