require 'open_food_network/split_products_by_distribution'

Spree::ProductsController.class_eval do
  include EnterprisesHelper
  include OrderCyclesHelper

  before_filter :require_distributor_chosen, only: :index

  respond_override :index => { :html => { :success => lambda {
        redirect_to main_app.enterprise_path(current_distributor)
      } } }

end
