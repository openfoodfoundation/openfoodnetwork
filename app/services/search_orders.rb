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

    @search = @search.result(distinct: true)

    if ['bill_address',
        'billing_address'].any?{ |param|
         params.dig(:q, :s)&.starts_with?(param)
       }
      @search = @search.left_joins(:bill_address).
        select('spree_addresses.*, spree_orders.*')
    end

    @search
  end

  def search_query
    base_query = ::Permissions::Order.new(current_user).editable_orders.not_empty
      .or(::Permissions::Order.new(current_user).editable_orders.finalized)

    return base_query if params[:shipping_method_id].blank?

    base_query
      .joins(shipments: :shipping_rates)
      .where(spree_shipping_rates: {
               selected: true,
               shipping_method_id: params[:shipping_method_id]
             })
  end
end
