# frozen_string_literal: true

class SearchOrders
  attr_reader :orders

  def initialize(params, current_user)
    @params = params
    @current_user = current_user

    @orders = fetch_orders
  end

  private

  attr_reader :params, :current_user

  def fetch_orders
    @search = search_query.
      includes(:payments, :subscription, :shipments, :bill_address, :distributor, :order_cycle).
      ransack(params[:q])

    return paginated_results if using_pagination?

    @search.result(distinct: true)
  end

  def search_query
    base_query = ::Permissions::Order.new(current_user).editable_orders
    return base_query unless params[:shipping_method_id]

    base_query
      .joins(shipments: :shipping_rates)
      .where(spree_shipping_rates: {
               selected: true,
               shipping_method_id: params[:shipping_method_id]
             })
  end

  def paginated_results
    @search.result(distinct: true)
      .page(params[:page])
      .per(params[:per_page])
  end

  def using_pagination?
    params[:page]
  end
end
