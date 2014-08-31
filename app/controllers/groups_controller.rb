class GroupsController < BaseController
  layout 'darkswarm'
  before_filter :load_active_distributors

  def index
    @groups = EnterpriseGroup.on_front_page.by_position
  end
end
