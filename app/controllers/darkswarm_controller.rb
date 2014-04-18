class DarkswarmController < BaseController
  layout 'darkswarm'
  
  # TODO
  # custom filter
  # Get list of producers
  # New?
  # "Orders closing soon" etc, details
  def index
    @active_distributors ||= Enterprise.distributors_with_active_order_cycles
  end
end
