class ShopController < BaseController
  layout "darkswarm"

  def index
    @distributor = current_distributor 
  end

  
end
