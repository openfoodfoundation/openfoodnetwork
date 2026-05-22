# frozen_string_literal: true

class ProductsController < BaseController
  def index
    @order_cycle_id = params[:order_cycle_id]
  end
end
