require "chili"
require "enterprises_distributor_info_rich_text_feature/engine"

module EnterprisesDistributorInfoRichTextFeature
  extend Chili::Base
  active_if { true } # edit this to activate/deactivate feature at runtime
end
