require 'csv'
require 'open_food_web/order_and_distributor_report'
require 'open_food_web/group_buy_report'
require 'open_food_web/order_grouper'

Spree::Admin::ReportsController.class_eval do

  Spree::Admin::ReportsController::AVAILABLE_REPORTS.merge!({:orders_and_distributors => {:name => "Orders And Distributors", :description => "Orders with distributor details"}})
  Spree::Admin::ReportsController::AVAILABLE_REPORTS.merge!({:group_buys => {:name => "Group Buys", :description => "Orders by supplier and variant"}})
  Spree::Admin::ReportsController::AVAILABLE_REPORTS.merge!({:bulk_coop => {:name => "Bulk Co-Op", :description => "Reports for Bulk Co-Op orders"}})
  Spree::Admin::ReportsController::AVAILABLE_REPORTS.merge!({:payments => {:name => "Payment Reports", :description => "Reports for Payments"}})

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

    @distributors = Spree::Distributor.all

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

  def bulk_coop
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
    line_items = orders.map { |o| o.line_items }.flatten

    @distributors = Spree::Distributor.all
    @report_type = params[:report_type]

    case params[:report_type]
    when "bulk_coop_supplier_report"

      header = ["Supplier", "Product", "Unit Size", "Variant", "Weight", "Sum Total", "Sum Max Total"]

      columns = [ proc { |lis| lis.first.variant.product.supplier.name },
        proc { |lis| lis.first.variant.product.name },
        proc { |lis| "UNIT SIZE" },
        proc { |lis| lis.first.variant.options_text },
        proc { |lis| lis.first.variant.weight },
        proc { |lis|  lis.sum { |li| li.quantity } },
        proc { |lis| lis.sum { |li| li.max_quantity || 0 } } ]

      rules = [ { group_by: proc { |li| li.variant.product.supplier },
        sort_by: proc { |supplier| supplier.name } },
        { group_by: proc { |li| li.variant.product },
        sort_by: proc { |product| product.name },
        summary_columns: [ proc { |lis| lis.first.variant.product.supplier.name },
          proc { |lis| lis.first.variant.product.name }, proc { |lis| "UNIT SIZE" },
          proc { |lis| "" }, proc { |lis| "" },
          proc { |lis|  lis.sum { |li| li.quantity * li.variant.weight } },
          proc { |lis| lis.sum { |li| (li.max_quantity || 0) * li.variant.weight } } ] },
        { group_by: proc { |li| li.variant },
        sort_by: proc { |variant| variant.options_text } } ]

    when "bulk_coop_allocation"

      header = ["Customer", "Product", "Unit Size", "Variant", "Weight", "Sum Total", "Sum Max Total"]

      columns = [ proc { |lis| lis.first.order.bill_address.firstname + " " + lis.first.order.bill_address.lastname },
        proc { |lis| lis.first.variant.product.name },
        proc { |lis| "UNIT SIZE" },
        proc { |lis| lis.first.variant.options_text },
        proc { |lis| lis.first.variant.weight },
        proc { |lis|  lis.sum { |li| li.quantity } },
        proc { |lis| lis.sum { |li| li.max_quantity || 0 } } ]

      rules = [ { group_by: proc { |li| li.variant.product },
        sort_by: proc { |product| product.name } },
        { group_by: proc { |li| li.variant },
        sort_by: proc { |variant| variant.options_text } },
        { group_by: proc { |li| li.order.user },
        sort_by: proc { |user| user.to_s } } ]

    when "bulk_coop_packing_sheets"

      header = ["Customer", "Product", "Variant", "Sum Total"]

      columns = [ proc { |lis| lis.first.order.bill_address.firstname + " " + lis.first.order.bill_address.lastname },
        proc { |lis| lis.first.variant.product.name },
        proc { |lis| lis.first.variant.options_text },
        proc { |lis|  lis.sum { |li| li.quantity } } ]

      rules = [ { group_by: proc { |li| li.variant.product },
        sort_by: proc { |product| product.name } },
        { group_by: proc { |li| li.variant },
        sort_by: proc { |variant| variant.options_text } },
        { group_by: proc { |li| li.order.user },
        sort_by: proc { |user| user.to_s } } ]

    when "bulk_coop_customer_payments"

      header = ["Customer", "Date of Order", "Total Cost", "Amount Owing", "Amount Paid"]

      columns = [ proc { |lis| lis.first.order.bill_address.firstname + " " + lis.first.order.bill_address.lastname },
        proc { |lis| lis.first.order.created_at.to_s },
        proc { |lis| lis.map { |li| li.order }.uniq.sum { |o| o.total } },
        proc { |lis| lis.map { |li| li.order }.uniq.sum { |o| o.outstanding_balance } },
        proc { |lis| lis.map { |li| li.order }.uniq.sum { |o| o.payment_total } } ]

      rules = [ { group_by: proc { |li| li.order.user },
        sort_by: proc { |user| user.to_s } },
        { group_by: proc { |li| li.order },
        sort_by: proc { |order|  order.created_at } } ]

    else # List all line items

      header = ["Supplier", "Product", "Unit Size", "Variant", "Weight", "Sum Total", "Sum Max Total"]

      columns = [ proc { |lis| lis.first.variant.product.supplier.name },
        proc { |lis| lis.first.variant.product.name },
        proc { |lis| "UNIT SIZE" },
        proc { |lis| lis.first.variant.options_text },
        proc { |lis| lis.first.variant.weight },
        proc { |lis|  lis.sum { |li| li.quantity } },
        proc { |lis| lis.sum { |li| li.max_quantity || 0 } } ]

      rules = [ { group_by: proc { |li| li.variant.product.supplier },
        sort_by: proc { |supplier| supplier.name } },
        { group_by: proc { |li| li.variant.product },
        sort_by: proc { |product| product.name } },
        { group_by: proc { |li| li.variant },
        sort_by: proc { |variant| variant.options_text } } ]
    end

    order_grouper = OpenFoodWeb::OrderGrouper.new rules, columns

    @header = header
    @table = order_grouper.table(line_items)
    csv_file_name = "bulk_coop.csv"

    render_report(@header, @table, params[:csv], csv_file_name)
  end

  def payments
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
    payments = orders.map { |o| o.payments.select { |payment| payment.completed? } }.flatten # Only select completed payments

    @distributors = Spree::Distributor.all
    @report_type = params[:report_type]

    case params[:report_type]
    when "payments_by_payment_type"
      table_items = payments

      header = ["Payment State", "Distributor", "Payment Type", "Total ($)"]

      columns = [ proc { |payments| payments.first.order.payment_state },
        proc { |payments| payments.first.order.distributor.name },
        proc { |payments| payments.first.payment_method.name },
        proc { |payments| payments.sum { |payment| payment.amount } } ]

      rules = [ { group_by: proc { |payment| payment.order.payment_state },
        sort_by: proc { |payment_state| payment_state } },
        { group_by: proc { |payment| payment.order.distributor },
        sort_by: proc { |distributor| distributor.name } },
        { group_by: proc { |payment| payment.payment_method },
        sort_by: proc { |method| method.name } } ]

    when "itemised_payment_totals"
      table_items = orders

      header = ["Payment State", "Distributor", "Product Total ($)", "Shipping Total ($)", "Outstanding Balance ($)", "Total ($)"]

      columns = [ proc { |orders| orders.first.payment_state },
        proc { |orders| orders.first.distributor.name },
        proc { |orders| orders.sum { |o| o.item_total } },
        proc { |orders| orders.sum { |o| o.ship_total } },
        proc { |orders| orders.sum { |o| o.outstanding_balance } },
        proc { |orders| orders.sum { |o| o.total } } ]

      rules = [ { group_by: proc { |order| order.payment_state },
        sort_by: proc { |payment_state| payment_state } },
        { group_by: proc { |order| order.distributor },
        sort_by: proc { |distributor| distributor.name } } ]

    when "payment_totals"
      table_items = orders

      header = ["Payment State", "Distributor", "Product Total ($)", "Shipping Total ($)", "Total ($)", "EFT ($)", "PayPal ($)", "Outstanding Balance ($)"]

      columns = [ proc { |orders| orders.first.payment_state },
        proc { |orders| orders.first.distributor.name },
        proc { |orders| orders.sum { |o| o.item_total } },
        proc { |orders| orders.sum { |o| o.ship_total } },
        proc { |orders| orders.sum { |o| o.total } },
        proc { |orders| orders.sum { |o| o.payments.select { |payment| payment.completed? && (payment.payment_method.name.to_s.include? "EFT") }.sum { |payment| payment.amount } } },
        proc { |orders| orders.sum { |o| o.payments.select { |payment| payment.completed? && (payment.payment_method.name.to_s.include? "PayPal") }.sum{ |payment| payment.amount } } },
        proc { |orders| orders.sum { |o| o.outstanding_balance } } ]

      rules = [ { group_by: proc { |order| order.payment_state },
        sort_by: proc { |payment_state| payment_state } },
        { group_by: proc { |order| order.distributor },
        sort_by: proc { |distributor| distributor.name } } ]

    else
      table_items = payments

      header = ["Payment State", "Distributor", "Payment Type", "Total ($)"]

      columns = [ proc { |payments| payments.first.order.payment_state },
        proc { |payments| payments.first.order.distributor.name },
        proc { |payments| payments.first.payment_method.name },
        proc { |payments| payments.sum { |payment| payment.amount } } ]

      rules = [ { group_by: proc { |payment| payment.order.payment_state },
        sort_by: proc { |payment_state| payment_state } },
        { group_by: proc { |payment| payment.order.distributor },
        sort_by: proc { |distributor| distributor.name } },
        { group_by: proc { |payment| payment.payment_method },
        sort_by: proc { |method| method.name } } ]

    end

    order_grouper = OpenFoodWeb::OrderGrouper.new rules, columns

    @header = header
    @table = order_grouper.table(table_items)
    csv_file_name = "payments.csv"

    render_report(@header, @table, params[:csv], csv_file_name)

  end

  def render_report (header, table, create_csv, csv_file_name)
    unless create_csv
      render :html => table
    else
      csv_string = CSV.generate do |csv|
        csv << header
       table.each { |row| csv << row }
      end
      send_data csv_string, :filename => csv_file_name
    end
  end
end