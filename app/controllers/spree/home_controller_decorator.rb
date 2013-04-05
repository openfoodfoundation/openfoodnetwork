require 'open_food_web/split_products_by_distribution'

Spree::HomeController.class_eval do
  include EnterprisesHelper
  include OpenFoodWeb::SplitProductsByDistribution

  respond_override :index => { :html => { :success => lambda {
        @products, @products_local, @products_remote = split_products_by_distribution @products, current_distributor
      } } }
end
