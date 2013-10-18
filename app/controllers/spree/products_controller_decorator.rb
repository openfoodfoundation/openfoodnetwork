require 'open_food_web/split_products_by_distribution'

Spree::ProductsController.class_eval do
  include EnterprisesHelper
  include OrderCyclesHelper
  include OpenFoodNetwork::SplitProductsByDistribution

  before_filter :require_distributor_chosen, only: :index

  respond_override :index => { :html => { :success => lambda {
        if current_order_cycle
          order_cycle_products = current_order_cycle.products
          @products.select! { |p| order_cycle_products.include? p }
        end
      } } }

end
