class SuburbsController < ActionController::Base
  def index
    @suburbs = Suburb.order(:name).where("lower(name) like ?", "%#{params[:term].downcase}%")
    render json: @suburbs.map{ |suburb| "#{suburb.name}, #{suburb.postcode}" }
  end
end