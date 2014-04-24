class HomeController < BaseController
  layout 'darkswarm'
  
  def index
    @active_distributors ||= Enterprise.distributors_with_active_order_cycles
  end

  def new_landing_page
  end

  def about_us
  end

  def temp_landing_page
    @groups = EnterpriseGroup.on_front_page.by_position
    render layout: false
  end
end
