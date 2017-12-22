class GroupsController < BaseController
  layout 'darkswarm'

  def index
    @groups = EnterpriseGroup.on_front_page.by_position
  end

  def show
    enable_embedded_shopfront
    if @shopfront_layout == 'embedded'
    	@hide_menu = true 
    	@show_powered_by_OFN = true
    end
    @group = EnterpriseGroup.find_by_permalink(params[:id]) || EnterpriseGroup.find(params[:id])
  end
end
