class HomeController < BaseController
  layout 'darkswarm'

  before_filter :enable_embedded_shopfront

  def index
    if ContentConfig.home_show_stats
      @num_distributors = cached_count('distributors', Enterprise.is_distributor.activated.visible)
      @num_producers = cached_count('producers', Enterprise.is_primary_producer.activated.visible)
      @num_orders = cached_count('orders', Spree::Order.complete)
      @num_users = cached_count(
        'users', Spree::Order.complete.select('DISTINCT spree_orders.user_id')
      )
    end
  end

  def sell; end

  private

  # Cache the value of the query count for 24 hours
  def cached_count(key, query)
    Rails.cache.fetch("home_stats_count_#{key}", expires_in: 1.day, race_condition_ttl: 10) do
      query.count
    end
  end
end
