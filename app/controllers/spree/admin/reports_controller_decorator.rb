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
    orders = @search.result.select { |o| o.completed? } # Only select complete orders
    line_items = orders.map { |o| o.line_items }.flatten

    # Ignore supplier conditions if "All" selected
    #if params[:supplier_id] && params[:supplier_id] != "All"
    #  line_items = line_items.select { |li| li.variant.product.supplier_id == params[:supplier_id] }
    #end

    #[Distributor.new(:id => nil, :name => 'All')]+
    @distributors = Spree::Distributor.all
    @report_type = params[:report_type]

    case params[:report_type]
    when "bulk_coop_supplier_report"
      rules = [ { group_by: Proc.new { |li| li.variant.product.supplier }, sort_by: Proc.new { |supplier| supplier.name } }, { group_by: Proc.new { |li| li.variant.product }, sort_by: Proc.new { |product| product.name }, summary_columns: [ Proc.new { |lis| lis.first.variant.product.supplier.name },  Proc.new { |lis| lis.first.variant.product.name }, Proc.new { |lis| "UNIT SIZE" }, Proc.new { |lis| "" }, Proc.new { |lis| "" }, Proc.new { |lis|  lis.sum { |li| li.quantity * li.variant.weight } }, Proc.new { |lis| lis.sum { |li| (li.max_quantity || 0) * li.variant.weight } } ] }, { group_by: Proc.new { |li| li.variant }, sort_by: Proc.new { |variant| variant.options_text } } ]
      columns = [ Proc.new { |lis| lis.first.variant.product.supplier.name },  Proc.new { |lis| lis.first.variant.product.name }, Proc.new { |lis| "UNIT SIZE" }, Proc.new { |lis| lis.first.variant.options_text }, Proc.new { |lis| lis.first.variant.weight }, Proc.new { |lis|  lis.sum { |li| li.quantity } }, Proc.new { |lis| lis.sum { |li| li.max_quantity || 0 } } ]
      header = ["Supplier","Product","Unit Size","Variant","Weight","Sum Total","Sum Max Total"]
    when "bulk_coop_allocation"
      rules = [ { group_by: Proc.new { |li| li.variant.product }, sort_by: Proc.new { |product| product.name } }, { group_by: Proc.new { |li| li.variant }, sort_by: Proc.new { |variant| variant.options_text } }, { group_by: Proc.new { |li| li.order.user }, sort_by: Proc.new { |user| user.to_s } } ]
      columns = [ Proc.new { |lis| lis.first.order.bill_address.firstname + " " + lis.first.order.bill_address.lastname },  Proc.new { |lis| lis.first.variant.product.name }, Proc.new { |lis| "UNIT SIZE" }, Proc.new { |lis| lis.first.variant.options_text }, Proc.new { |lis| lis.first.variant.weight }, Proc.new { |lis|  lis.sum { |li| li.quantity } }, Proc.new { |lis| lis.sum { |li| li.max_quantity || 0 } } ]     
      header = ["Customer","Product","Unit Size","Variant","Weight","Sum Total","Sum Max Total"]
    when "bulk_coop_packing_sheets"
      rules = [ { group_by: Proc.new { |li| li.variant.product }, sort_by: Proc.new { |product| product.name } }, { group_by: Proc.new { |li| li.variant }, sort_by: Proc.new { |variant| variant.options_text } }, { group_by: Proc.new { |li| li.order.user }, sort_by: Proc.new { |user| user.to_s } } ]
      columns = [ Proc.new { |lis| lis.first.order.bill_address.firstname + " " + lis.first.order.bill_address.lastname },  Proc.new { |lis| lis.first.variant.product.name }, Proc.new { |lis| lis.first.variant.options_text }, Proc.new { |lis|  lis.sum { |li| li.quantity } } ]     
      header = ["Customer","Product","Variant","Sum Total"]
    when "bulk_coop_customer_payments"
      rules = [ { group_by: Proc.new { |li| li.order.user }, sort_by: Proc.new { |user| user.to_s } }, { group_by: Proc.new { |li| li.order }, sort_by: Proc.new { |order|  order.created_at } } ]
      columns = [ Proc.new { |lis| lis.first.order.bill_address.firstname + " " + lis.first.order.bill_address.lastname }, Proc.new { |lis| lis.first.order.created_at.to_s },  Proc.new { |lis| lis.map { |li| li.order }.to_set.to_a.sum { |o| o.total } }, Proc.new { |lis| lis.map { |li| li.order }.to_set.to_a.sum { |o| o.outstanding_balance } }, Proc.new { |lis| lis.map { |li| li.order }.to_set.to_a.sum { |o| o.payment_total } } ]     
      header = ["Customer","Date of Order","Total Cost","Amount Owing","Amount Paid"]
    else # List all line items
      rules = [ { group_by: Proc.new { |li| li.variant.product.supplier }, sort_by: Proc.new { |supplier| supplier.name } }, { group_by: Proc.new { |li| li.variant.product }, sort_by: Proc.new { |product| product.name } }, { group_by: Proc.new { |li| li.variant }, sort_by: Proc.new { |variant| variant.options_text } } ]
      columns = [ Proc.new { |lis| lis.first.variant.product.supplier.name },  Proc.new { |lis| lis.first.variant.product.name }, Proc.new { |lis| "UNIT SIZE" }, Proc.new { |lis| lis.first.variant.options_text }, Proc.new { |lis| lis.first.variant.weight }, Proc.new { |lis|  lis.sum { |li| li.quantity } }, Proc.new { |lis| lis.sum { |li| li.max_quantity || 0 } } ]
      header = ["Supplier","Product","Unit Size","Variant","Weight","Sum Total","Sum Max Total"]
    end

    order_grouper = OpenFoodWeb::OrderGrouper.new rules, columns

    @header = header
    @table = order_grouper.table(line_items)

    unless params[:csv]
      render :html => @table
    else
      csv_string = CSV.generate do |csv|
        csv << @header
       @table.each { |row| csv << row }
      end
      send_data csv_string, :filename => "bulk_coop.csv"
    end
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
    orders = @search.result.select { |o| o.complete? } # Only select complete orders
    payments = orders.map { |o| o.payments.select { |payment| payment.completed? } }.flatten # Only select completed payments

    # Ignore supplier conditions if "All" selected
    #if params[:supplier_id] && params[:supplier_id] != "All"
    #  line_items = line_items.select { |li| li.variant.product.supplier_id == params[:supplier_id] }
    #end

    #[Distributor.new(:id => nil, :name => 'All')]+
    @distributors = Spree::Distributor.all
    @report_type = params[:report_type]

    case params[:report_type]
    when "payments_by_payment_type"
      table_items = payments
      rules = [ { group_by: Proc.new { |payment| payment.order.payment_state }, sort_by: Proc.new { |payment_state| payment_state } }, { group_by: Proc.new { |payment| payment.order.distributor }, sort_by: Proc.new { |distributor| distributor.name } }, { group_by: Proc.new { |payment| payment.payment_method }, sort_by: Proc.new { |method| method.name } } ]
      columns = [ Proc.new { |payments| payments.first.order.payment_state }, Proc.new { |payments| payments.first.order.distributor.name },  Proc.new { |payments| payments.first.payment_method.name }, Proc.new { |payments| payments.sum { |payment| payment.amount } } ]
      header = ["Payment State", "Distributor", "Payment Type", "Total ($)"]
    when "itemised_payment_totals"
      table_items = orders
      rules = [ { group_by: Proc.new { |order| order.payment_state }, sort_by: Proc.new { |payment_state| payment_state } }, { group_by: Proc.new { |order| order.distributor }, sort_by: Proc.new { |distributor| distributor.name } } ]
      columns = [ Proc.new { |orders| orders.first.payment_state }, Proc.new { |orders| orders.first.distributor.name },  Proc.new { |orders| orders.sum { |o| o.item_total } }, Proc.new { |orders| orders.sum { |o| o.ship_total } }, Proc.new { |orders| orders.sum { |o| o.outstanding_balance } }, Proc.new { |orders| orders.sum { |o| o.total } } ]
      header = ["Payment State", "Distributor", "Product Total ($)", "Shipping Total ($)", "Outstanding Balance ($)", "Total ($)"]
    when "payment_totals"
      table_items = orders
      rules = [ { group_by: Proc.new { |order| order.payment_state }, sort_by: Proc.new { |payment_state| payment_state } }, { group_by: Proc.new { |order| order.distributor }, sort_by: Proc.new { |distributor| distributor.name } } ]
      columns = [ Proc.new { |orders| orders.first.payment_state }, Proc.new { |orders| orders.first.distributor.name }, Proc.new { |orders| orders.sum { |o| o.item_total } }, Proc.new { |orders| orders.sum { |o| o.ship_total } }, Proc.new { |orders| orders.sum { |o| o.total } },  Proc.new { |orders| orders.sum { |o| o.payments.select { |payment| payment.completed? && (payment.payment_method.name.to_s.include? "EFT") }.sum { |payment| payment.amount } } }, Proc.new { |orders| orders.sum { |o| o.payments.select { |payment| payment.completed? && (payment.payment_method.name.to_s.include? "PayPal") }.sum{ |payment| payment.amount } } }, Proc.new { |orders| orders.sum { |o| o.outstanding_balance } } ]
      header = ["Payment State", "Distributor", "Product Total ($)", "Shipping Total ($)", "Total ($)", "EFT ($)", "PayPal ($)", "Outstanding Balance ($)"]
    else
      table_items = payments
      rules = [ { group_by: Proc.new { |payment| payment.order.payment_state }, sort_by: Proc.new { |payment_state| payment_state } }, { group_by: Proc.new { |payment| payment.order.distributor }, sort_by: Proc.new { |distributor| distributor.name } }, { group_by: Proc.new { |payment| payment.payment_method }, sort_by: Proc.new { |method| method.name } } ]
      columns = [ Proc.new { |payments| payments.first.order.payment_state }, Proc.new { |payments| payments.first.order.distributor.name },  Proc.new { |payments| payments.first.payment_method.name }, Proc.new { |payments| payments.sum { |payment| payment.amount } } ]
      header = ["Payment State", "Distributor", "Payment Type", "Total ($)"]
    end

    order_grouper = OpenFoodWeb::OrderGrouper.new rules, columns

    @header = header
    @table = order_grouper.table(table_items)

    unless params[:csv]
      render :html => @table
    else
      csv_string = CSV.generate do |csv|
        csv << @header
       @table.each { |row| csv << row }
      end
      send_data csv_string, :filename => "payments.csv"
    end
  end
end