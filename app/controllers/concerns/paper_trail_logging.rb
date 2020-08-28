# frozen_string_literal: true

# This concern adds additional Papertrail logging options so that the id of the
# user that modified the record is also logged.
# See: https://github.com/paper-trail-gem/paper_trail#setting-whodunnit-with-a-controller-callback

module PaperTrailLogging
  extend ActiveSupport::Concern

  included do
    before_action :set_paper_trail_whodunnit
  end

  def user_for_paper_trail
    spree_current_user
  end
end
