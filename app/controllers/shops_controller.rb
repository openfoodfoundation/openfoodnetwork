class ShopsController < BaseController
  layout 'darkswarm'

  before_filter :enable_embedded_shopfront

  def index
  end
end
