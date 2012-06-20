class ApplicationController < ActionController::Base
  protect_from_forgery

  before_filter :load_suppliers_and_distributors

  private
  def load_suppliers_and_distributors
    @suppliers = Spree::Supplier.all
    @distributors = Spree::Distributor.all
  end

end
