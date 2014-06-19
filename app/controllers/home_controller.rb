class HomeController < BaseController
  layout 'darkswarm'
  before_filter :load_active_distributors
  
  def index
  end

  def about_us
  end
end

