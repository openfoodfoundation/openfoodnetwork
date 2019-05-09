require 'open_food_network/products_cache_integrity_checker'

module Admin
  class CacheSettingsController < Spree::Admin::BaseController
    def edit
      @results = Exchange.cachable.limit(5).map do |exchange|
        checker = OpenFoodNetwork::ProductsCacheIntegrityChecker
          .new(exchange.receiver, exchange.order_cycle)

        {
          distributor: exchange.receiver,
          order_cycle: exchange.order_cycle,
          status: checker.ok?,
          diff: checker.diff
        }
      end
    end

    def update
      Spree::Config.set(params[:preferences])

      respond_to do |format|
        format.html { redirect_to main_app.edit_admin_cache_settings_path }
      end
    end
  end
end
