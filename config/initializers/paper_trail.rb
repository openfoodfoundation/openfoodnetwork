PaperTrail.config.track_associations = false

module PaperTrail
  class Version < ActiveRecord::Base
    attr_accessible :custom_data
  end
end
