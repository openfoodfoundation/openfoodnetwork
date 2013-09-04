require 'open_food_web/split_products_by_distribution'

Spree::ProductsController.class_eval do
  include EnterprisesHelper
  include OrderCyclesHelper
  include OpenFoodWeb::SplitProductsByDistribution

  respond_override :index => { :html => { :success => lambda {
        @products = current_order_cycle.products if current_order_cycle
      } } }

end
