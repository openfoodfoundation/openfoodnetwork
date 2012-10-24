require 'open_food_web/split_products_by_distributor'

Spree::TaxonsController.class_eval do
  include DistributorsHelper
  include OpenFoodWeb::SplitProductsByDistributor

  respond_override :show => { :html => { :success => lambda {
        @products, @products_local, @products_remote = split_products_by_distributor @products, current_distributor
      } } }
end
