class ApplicationController < ActionController::Base
  protect_from_forgery

  before_filter :load_data_for_menu
  before_filter :load_data_for_sidebar

  private
  def load_data_for_menu
    @cms_site = Cms::Site.where(:identifier => 'open-food-web').first
  end


  def load_data_for_sidebar
    @suppliers = Supplier.all
    @distributors = Distributor.with_active_products_on_hand.by_name
  end

end
