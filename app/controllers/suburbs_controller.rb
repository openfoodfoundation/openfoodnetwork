class SuburbsController < ActionController::Base
  def index
    @suburbs = Suburb.matching(params[:term]).order(:name).limit(8)
  end
end
