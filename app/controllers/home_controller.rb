class HomeController < BaseController
  layout 'darkswarm'
  
  def index
    @active_distributors ||= Enterprise.distributors_with_active_order_cycles
    @enterprises = Enterprise.visible
  end

  def about_us
  end
end
