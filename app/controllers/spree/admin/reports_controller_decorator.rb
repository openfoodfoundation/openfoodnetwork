require 'csv'
require 'open_food_web/order_and_distributor_report'
require 'open_food_web/group_buy_report'

Spree::Admin::ReportsController.class_eval do

  Spree::Admin::ReportsController::AVAILABLE_REPORTS.merge!({:orders_and_distributors => {:name => "Orders And Distributors", :description => "Orders with distributor details"}})
  Spree::Admin::ReportsController::AVAILABLE_REPORTS.merge!({:group_buys => {:name => "Group Buys", :description => "Orders by supplier and variant"}})

  def orders_and_distributors
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
    orders = @search.result

    @report = OpenFoodWeb::OrderAndDistributorReport.new orders
    unless params[:csv]
      render :html => @report
    else
      csv_string = CSV.generate do |csv|
        csv << @report.header
        @report.table.each { |row| csv << row }
      end
      send_data csv_string, :filename => "orders_and_distributors.csv"
    end
  end

  def group_buys
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
    orders = @search.result
    
    @distributors = Enterprise.is_distributor

    @report = OpenFoodWeb::GroupBuyReport.new orders
    unless params[:csv]
      render :html => @report
    else
      csv_string = CSV.generate do |csv|
        csv << @report.header
        @report.table.each { |row| csv << row }
      end
      send_data csv_string, :filename => "group_buy.csv"
    end
  end

end
