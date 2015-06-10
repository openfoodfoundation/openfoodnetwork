class HomeController < BaseController
  layout 'darkswarm'

  def index
    @num_hubs = Enterprise.is_hub.count
    @num_producers = Enterprise.is_primary_producer.count
    @num_users = Spree::User.joins(:orders).count('DISTINCT spree_users.*')
    @num_orders = Spree::Order.complete.count
  end

  def about_us
  end
end
