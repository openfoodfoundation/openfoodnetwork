require 'open_food_web/split_products_by_distributor'

Spree::ProductsController.class_eval do
  include Spree::DistributorsHelper
  include OpenFoodWeb::SplitProductsByDistributor

  before_filter :load_distributors, :only => :show

  respond_override :index => { :html => { :success => lambda {
        @products, @products_local, @products_remote = split_products_by_distributor @products, current_distributor
      } } }


  def load_distributors
    @distributors = Spree::Distributor.by_name
  end

end
