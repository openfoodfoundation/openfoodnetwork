class ApplicationController < ActionController::Base
  protect_from_forgery

  before_filter :load_data_for_sidebar

  private
  def load_data_for_sidebar
    @suppliers = Spree::Supplier.all
    @distributors = Spree::Distributor.with_products
  end

end
