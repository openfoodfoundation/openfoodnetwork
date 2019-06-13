class HomeController < BaseController
  layout 'darkswarm'

  before_filter :enable_embedded_shopfront

  def index
    if ContentConfig.home_show_stats
      @num_distributors = Enterprise.is_distributor.activated.visible.count
      @num_producers = Enterprise.is_primary_producer.activated.visible.count
      @num_users = Spree::Order.complete.count('DISTINCT user_id')
      @num_orders = Spree::Order.complete.count
    end
  end

  def sell; end
end
