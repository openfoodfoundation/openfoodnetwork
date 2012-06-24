require 'open_food_web/split_products_by_distributor'

Spree::ProductsController.class_eval do
  include Spree::DistributorsHelper
  include OpenFoodWeb::SplitProductsByDistributor

  respond_override :index => { :html => { :success => lambda {
        @products, @products_local, @products_remote = split_products_by_distributor @products, current_distributor
      } } }

end
