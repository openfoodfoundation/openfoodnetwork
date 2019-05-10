class ShopsController < BaseController
  layout 'darkswarm'

  before_filter :enable_embedded_shopfront

  def index
    @enterprises = Enterprise
      .activated
      .visible
      .is_distributor
      .includes(address: :state)
      .includes(:properties)
      .includes(supplied_products: :properties)
      .all
  end
end
