require "chili"
require "local_organics_feature/engine"

module LocalOrganicsFeature
  extend Chili::Base
  active_if { true } # edit this to activate/deactivate feature at runtime
end
