# frozen_string_literal: true

ActsAsTaggableOn.force_lowercase = true

# Monkey patch suggested as workaround to the allowlisted issue
# This may be removed when an official fix is included in Ransack
# As suggested in :
# - https://github.com/activerecord-hackery/ransack/discussions/1416
# - https://github.com/activerecord-hackery/ransack/issues/1393
#
module ActsAsTaggableOn
  class Tag
    class << self
      def ransackable_associations(_auth_object = nil)
        ["taggings"]
      end

      def ransackable_attributes(_auth_object = nil)
        ["name"]
      end
    end
  end
end
