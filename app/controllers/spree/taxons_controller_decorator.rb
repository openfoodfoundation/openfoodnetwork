require 'open_food_web/split_products_by_distribution'

Spree::TaxonsController.class_eval do
  include EnterprisesHelper
  include OrderCyclesHelper
  include OpenFoodWeb::SplitProductsByDistribution

  respond_override :show => { :html => { :success => lambda {
        @products, @products_local, @products_remote = split_products_by_distribution @products, current_distributor, current_order_cycle
      } } }
end
