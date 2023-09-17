# frozen_string_literal: true

class HomeController < BaseController
  layout 'darkswarm'

  def index
    load_home_stats if ContentConfig.home_show_stats
  end

  def sell; end

  def unauthorized
    render 'shared/unauthorized', status: :unauthorized
  end

  private

  # Cache the value of the query count
  def cached_count(statistic, query)
    CacheService.home_stats(statistic) { query.count }
  end

  # Load statistics for the home page
  def load_home_stats
    @num_distributors = cached_count(
      'distributors',
      Enterprise.is_distributor.activated.visible
    )

    @num_producers = cached_count(
      'producers',
      Enterprise.is_primary_producer.activated.visible
    )

    @num_orders = cached_count(
      'orders',
      Spree::Order.complete
    )

    @num_users = cached_count(
      'users',
      Spree::Order.complete.select('DISTINCT spree_orders.user_id')
    )
  end
end
