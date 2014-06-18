class MapController < BaseController
  layout 'darkswarm'
  before_filter :load_active_distributors
  before_filter :load_visible_enterprises

  def index
  end
end
