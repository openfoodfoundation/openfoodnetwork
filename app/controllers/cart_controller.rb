class CartController < Spree::Api::BaseController
  respond_to :json

  def new
    @cart = Cart.new(current_api_user)
    if @cart.save
      respond_with(@cart, :status => 201)
    else
      invalid_resource!(@cart)
    end
  end

  def show
    @cart = Cart.find(params[:id])
    respond_with(@cart)
  end

  def add_product
  end

end
