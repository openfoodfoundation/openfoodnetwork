module OpenFoodNetwork
  class CartController < ApplicationController
    respond_to :json

    # before_filter :authorize_read!, :except => [:index, :search, :create]

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

    def add_variant
      @cart = Cart.find(params[:cart_id])
      distributor = Enterprise.find_by_permalink(params[:distributor_id])
      order_cycle = OrderCycle.find(params[:order_cycle_id]) if params[:order_cycle_id]

      if @cart.add_variant params[:variant_id], params[:quantity], distributor, order_cycle, current_currency
        respond_with(@cart)
      else
        respond_with(@cart.populate_errors)
      end
    end

    private

    def current_currency
      Spree::Config[:currency]
    end
  end
end
