module Spree
  module DistributorsHelper
    def current_distributor
      @current_distributor ||= current_order(false).andand.distributor
    end
  end
end
