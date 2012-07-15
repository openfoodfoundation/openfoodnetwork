require 'csv'

Spree::Admin::ReportsController.class_eval do

  Spree::Admin::ReportsController::AVAILABLE_REPORTS.merge!({:orders => {:name => "Orders", :description => "Orders with distributor details"}})

  def orders
    params[:q] = {} unless params[:q]

    if params[:q][:created_at_gt].blank?
      params[:q][:created_at_gt] = Time.zone.now.beginning_of_month
    else
      params[:q][:created_at_gt] = Time.zone.parse(params[:q][:created_at_gt]).beginning_of_day rescue Time.zone.now.beginning_of_month
    end

    if params[:q] && !params[:q][:created_at_lt].blank?
      params[:q][:created_at_lt] = Time.zone.parse(params[:q][:created_at_lt]).end_of_day rescue ""
    end
    params[:q][:meta_sort] ||= "created_at.desc"

    @search = Spree::Order.complete.search(params[:q])
    @orders = @search.result

    if(!params[:csv])
      render :html => @orders
    else
      csv_string = CSV.generate do |csv|
        csv << ["Order date", "Order Id", "Name","Email", "SKU", "Item cost", "Quantity", "Cost", "Shipping cost", "Distributor", "Distributor address", "Distributor city", "Distributor postcode"]
        puts @orders
        @orders.each do |order|
          order.line_items.each do |line_item|
            csv << [order.created_at, order.id, order.bill_address.full_name, order.user.email,
              line_item.product.sku, line_item.product.name, line_item.quantity, line_item.price * line_item.quantity, line_item.itemwise_shipping_cost,
              order.distributor.pickup_address.full_name, order.distributor.pickup_address.address1, order.distributor.pickup_address.city, order.distributor.pickup_address.zipcode ]
          end
        end
      end
      send_data csv_string
    end
  end

end