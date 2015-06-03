class GroupsController < BaseController
  layout 'darkswarm'

  def index
    @groups = EnterpriseGroup.on_front_page.by_position
  end

  def show
    @group = EnterpriseGroup.find_by_permalink(params[:id]) || EnterpriseGroup.find(params[:id])
  end
end
