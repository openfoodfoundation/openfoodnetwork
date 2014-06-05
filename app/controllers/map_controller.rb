class MapController < BaseController
  layout 'darkswarm'
  def index
    @enterprises = Enterprise.visible
  end
end
