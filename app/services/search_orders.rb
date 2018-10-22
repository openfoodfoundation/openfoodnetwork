class SearchOrders
  attr_reader :orders

  def initialize(params, current_user)
    @params = params
    @current_user = current_user

    @orders = fetch_orders
  end

  def pagination_data
    return unless using_pagination?
    {
      results: @orders.total_count,
      pages: @orders.num_pages,
      page: params[:page].to_i,
      per_page: params[:per_page].to_i
    }
  end

  private

  attr_reader :params, :current_user

  def fetch_orders
    @search = OpenFoodNetwork::Permissions.new(current_user).editable_orders.ransack(params[:q])

    return paginated_results if using_pagination?
    @search.result
  end

  def paginated_results
    @search.result
      .page(params[:page])
      .per(params[:per_page] || Spree::Config[:orders_per_page])
  end

  def using_pagination?
    params[:per_page]
  end
end
