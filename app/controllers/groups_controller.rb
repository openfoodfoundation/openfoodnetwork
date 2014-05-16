class GroupsController < BaseController
  layout 'darkswarm'

  def index
    @groups = EnterpriseGroup.on_front_page.by_position
  end
end
