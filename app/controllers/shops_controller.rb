class ShopsController < BaseController
  layout 'darkswarm'

  before_filter :enable_embedded_shopfront

  def index
    @enterprises = Enterprise
      .activated
      .includes(address: :state)
      .includes(:properties)
      .all
  end
end
