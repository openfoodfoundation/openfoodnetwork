class ProducersController < BaseController
  layout 'darkswarm'
  before_filter :load_active_distributors
  
  def index
  end
end
