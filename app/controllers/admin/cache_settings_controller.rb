require 'open_food_network/products_cache_integrity_checker'

class Admin::CacheSettingsController < Spree::Admin::BaseController

  def show
    @results = Exchange.cachable.map do |exchange|
      checker = OpenFoodNetwork::ProductsCacheIntegrityChecker.new(exchange.receiver, exchange.order_cycle)

      {distributor: exchange.receiver, order_cycle: exchange.order_cycle, status: checker.ok?, diff: checker.diff}
    end
  end

end
