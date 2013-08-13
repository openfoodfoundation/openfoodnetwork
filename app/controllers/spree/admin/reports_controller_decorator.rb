require 'csv'
require 'open_food_web/order_and_distributor_report'
require 'open_food_web/group_buy_report'
require 'open_food_web/order_grouper'

Spree::Admin::ReportsController.class_eval do

  Spree::Admin::ReportsController::AVAILABLE_REPORTS.merge!({:orders_and_distributors => {:name => "Orders And Distributors", :description => "Orders with distributor details"}})
  Spree::Admin::ReportsController::AVAILABLE_REPORTS.merge!({:group_buys => {:name => "Group Buys", :description => "Orders by supplier and variant"}})
  Spree::Admin::ReportsController::AVAILABLE_REPORTS.merge!({:bulk_coop => {:name => "Bulk Co-Op", :description => "Reports for Bulk Co-Op orders"}})
  Spree::Admin::ReportsController::AVAILABLE_REPORTS.merge!({:payments => {:name => "Payment Reports", :description => "Reports for Payments"}})
  Spree::Admin::ReportsController::AVAILABLE_REPORTS.merge!({:order_cycles => {:name => "Order Cycle Reports", :description => "Reports for Order Cycles"}})

  def orders_and_distributors
    params[:q] = {} unless params[:q]

    if params[:q][:completed_at_gt].blank?
      params[:q][:completed_at_gt] = Time.zone.now.beginning_of_month
    else
      params[:q][:completed_at_gt] = Time.zone.parse(params[:q][:completed_at_gt]).beginning_of_day rescue Time.zone.now.beginning_of_month
    end

    if params[:q] && !params[:q][:completed_at_lt].blank?
      params[:q][:completed_at_lt] = Time.zone.parse(params[:q][:completed_at_lt]).end_of_day rescue ""
    end
    params[:q][:meta_sort] ||= "completed_at.desc"

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

    if params[:q][:completed_at_gt].blank?
      params[:q][:completed_at_gt] = Time.zone.now.beginning_of_month
    else
      params[:q][:completed_at_gt] = Time.zone.parse(params[:q][:completed_at_gt]).beginning_of_day rescue Time.zone.now.beginning_of_month
    end

    if params[:q] && !params[:q][:completed_at_lt].blank?
      params[:q][:completed_at_lt] = Time.zone.parse(params[:q][:completed_at_lt]).end_of_day rescue ""
    end
    params[:q][:meta_sort] ||= "completed_at.desc"

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

  def bulk_coop
    params[:q] = {} unless params[:q]

    if params[:q][:completed_at_gt].blank?
      params[:q][:completed_at_gt] = Time.zone.now.beginning_of_month
    else
      params[:q][:completed_at_gt] = Time.zone.parse(params[:q][:completed_at_gt]).beginning_of_day rescue Time.zone.now.beginning_of_month
    end

    if params[:q] && !params[:q][:completed_at_lt].blank?
      params[:q][:completed_at_lt] = Time.zone.parse(params[:q][:completed_at_lt]).end_of_day rescue ""
    end
    params[:q][:meta_sort] ||= "completed_at.desc"

    @search = Spree::Order.complete.search(params[:q])
    orders = @search.result
    line_items = orders.map { |o| o.line_items }.flatten

    @distributors = Enterprise.is_distributor
    @report_type = params[:report_type]

    case params[:report_type]
    when "bulk_coop_supplier_report"

      header = ["Supplier", "Product", "Unit Size", "Variant", "Weight", "Sum Total", "Sum Max Total", "Units Required", "Remainder"]

      columns = [ proc { |lis| lis.first.variant.product.supplier.name },
        proc { |lis| lis.first.variant.product.name },
        proc { |lis| lis.first.variant.product.group_buy ? (lis.first.variant.product.group_buy_unit_size || 0.0) : "" },
        proc { |lis| lis.first.variant.options_text },
        proc { |lis| lis.first.variant.weight || 0 },
        proc { |lis|  lis.sum { |li| li.quantity } },
        proc { |lis| lis.sum { |li| li.max_quantity || 0 } },
        proc { |lis| "" },
        proc { |lis| "" } ]

      rules = [ { group_by: proc { |li| li.variant.product.supplier },
        sort_by: proc { |supplier| supplier.name } },
        { group_by: proc { |li| li.variant.product },
        sort_by: proc { |product| product.name },
        summary_columns: [ proc { |lis| lis.first.variant.product.supplier.name },
          proc { |lis| lis.first.variant.product.name },
          proc { |lis| lis.first.variant.product.group_buy ? (lis.first.variant.product.group_buy_unit_size || 0.0) : "" },
          proc { |lis| "" },
          proc { |lis| "" },
          proc { |lis| lis.sum { |li| (li.quantity || 0) * (li.variant.weight || 0) } },
          proc { |lis| lis.sum { |li| (li.max_quantity || 0) * (li.variant.weight || 0) } },
          proc { |lis| ( (lis.first.variant.product.group_buy_unit_size || 0).zero? ? 0 : ( lis.sum { |li| ( [li.max_quantity || 0, li.quantity || 0].max ) * (li.variant.weight || 0) } / lis.first.variant.product.group_buy_unit_size ) ).floor },
          proc { |lis| lis.sum { |li| ( [li.max_quantity || 0, li.quantity || 0].max) * (li.variant.weight || 0) } - ( ( (lis.first.variant.product.group_buy_unit_size || 0).zero? ? 0 : ( lis.sum { |li| ( [li.max_quantity || 0, li.quantity || 0].max) * (li.variant.weight || 0) } / lis.first.variant.product.group_buy_unit_size ) ).floor * (lis.first.variant.product.group_buy_unit_size || 0) ) } ] },
        { group_by: proc { |li| li.variant },
        sort_by: proc { |variant| variant.options_text } } ]

    when "bulk_coop_allocation"

      header = ["Customer", "Product", "Unit Size", "Variant", "Weight", "Sum Total", "Sum Max Total", "Total Allocated", "Remainder"]

      columns = [ proc { |lis| lis.first.order.bill_address.firstname + " " + lis.first.order.bill_address.lastname },
        proc { |lis| lis.first.variant.product.name },
        proc { |lis| lis.first.variant.product.group_buy ? (lis.first.variant.product.group_buy_unit_size || 0.0) : "" },
        proc { |lis| lis.first.variant.options_text },
        proc { |lis| lis.first.variant.weight || 0 },
        proc { |lis| lis.sum { |li| li.quantity } },
        proc { |lis| lis.sum { |li| li.max_quantity || 0 } },
        proc { |lis| "" },
        proc { |lis| "" } ]

      rules = [ { group_by: proc { |li| li.variant.product },
        sort_by: proc { |product| product.name },
        summary_columns: [ proc { |lis| "TOTAL" },
          proc { |lis| lis.first.variant.product.name },
          proc { |lis| lis.first.variant.product.group_buy ? (lis.first.variant.product.group_buy_unit_size || 0.0) : "" },
          proc { |lis| "" },
          proc { |lis| "" },
          proc { |lis| lis.sum { |li| li.quantity * (li.variant.weight || 0) } },
          proc { |lis| lis.sum { |li| (li.max_quantity || 0) * (li.variant.weight || 0) } },
          proc { |lis| ( (lis.first.variant.product.group_buy_unit_size || 0).zero? ? 0 : ( lis.sum { |li| ( [li.max_quantity || 0, li.quantity || 0].max ) * (li.variant.weight || 0) } / lis.first.variant.product.group_buy_unit_size ) ).floor * (lis.first.variant.product.group_buy_unit_size || 0) },
          proc { |lis| lis.sum { |li| ( [li.max_quantity || 0, li.quantity || 0].max ) * (li.variant.weight || 0) } - ( ( (lis.first.variant.product.group_buy_unit_size || 0).zero? ? 0 : ( lis.sum { |li| ( [li.max_quantity || 0, li.quantity || 0].max ) * (li.variant.weight || 0) } / lis.first.variant.product.group_buy_unit_size ) ).floor * (lis.first.variant.product.group_buy_unit_size || 0) ) } ] },
        { group_by: proc { |li| li.variant },
        sort_by: proc { |variant| variant.options_text } },
        { group_by: proc { |li| li.order },
        sort_by: proc { |order| order.to_s } } ]

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
        { group_by: proc { |li| li.order },
        sort_by: proc { |order| order.to_s } } ]

    when "bulk_coop_customer_payments"

      header = ["Customer", "Date of Order", "Total Cost", "Amount Owing", "Amount Paid"]

      columns = [ proc { |lis| lis.first.order.bill_address.firstname + " " + lis.first.order.bill_address.lastname },
        proc { |lis| lis.first.order.completed_at.to_s },
        proc { |lis| lis.map { |li| li.order }.uniq.sum { |o| o.total } },
        proc { |lis| lis.map { |li| li.order }.uniq.sum { |o| o.outstanding_balance } },
        proc { |lis| lis.map { |li| li.order }.uniq.sum { |o| o.payment_total } } ]

      rules = [ { group_by: proc { |li| li.order },
        sort_by: proc { |order|  order.completed_at } } ]

    else # List all line items

      header = ["Supplier", "Product", "Unit Size", "Variant", "Weight", "Sum Total", "Sum Max Total", "Units Required", "Remainder"]

      columns = [ proc { |lis| lis.first.variant.product.supplier.name },
        proc { |lis| lis.first.variant.product.name },
        proc { |lis| lis.first.variant.product.group_buy ? (lis.first.variant.product.group_buy_unit_size || 0.0) : "" },
        proc { |lis| lis.first.variant.options_text },
        proc { |lis| lis.first.variant.weight || 0 },
        proc { |lis|  lis.sum { |li| li.quantity } },
        proc { |lis| lis.sum { |li| li.max_quantity || 0 } },
        proc { |lis| "" },
        proc { |lis| "" } ]

      rules = [ { group_by: proc { |li| li.variant.product.supplier },
        sort_by: proc { |supplier| supplier.name } },
        { group_by: proc { |li| li.variant.product },
        sort_by: proc { |product| product.name },
        summary_columns: [ proc { |lis| lis.first.variant.product.supplier.name },
          proc { |lis| lis.first.variant.product.name },
          proc { |lis| lis.first.variant.product.group_buy ? (lis.first.variant.product.group_buy_unit_size || 0.0) : "" },
          proc { |lis| "" },
          proc { |lis| "" },
          proc { |lis| lis.sum { |li| li.quantity * (li.variant.weight || 0) } },
          proc { |lis| lis.sum { |li| (li.max_quantity || 0) * (li.variant.weight || 0) } },
          proc { |lis| ( (lis.first.variant.product.group_buy_unit_size || 0).zero? ? 0 : ( lis.sum { |li| ( [li.max_quantity || 0, li.quantity || 0].max ) * (li.variant.weight || 0) } / lis.first.variant.product.group_buy_unit_size ) ).floor },
          proc { |lis| lis.sum { |li| ( [li.max_quantity || 0, li.quantity || 0].max ) * (li.variant.weight || 0) } - ( ( (lis.first.variant.product.group_buy_unit_size || 0).zero? ? 0 : ( lis.sum { |li| ( [li.max_quantity || 0, li.quantity || 0].max ) * (li.variant.weight || 0) } / lis.first.variant.product.group_buy_unit_size ) ).floor * (lis.first.variant.product.group_buy_unit_size || 0) ) } ] },
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

    if params[:q][:completed_at_gt].blank?
      params[:q][:completed_at_gt] = Time.zone.now.beginning_of_month
    else
      params[:q][:completed_at_gt] = Time.zone.parse(params[:q][:completed_at_gt]).beginning_of_day rescue Time.zone.now.beginning_of_month
    end

    if params[:q] && !params[:q][:completed_at_lt].blank?
      params[:q][:completed_at_lt] = Time.zone.parse(params[:q][:completed_at_lt]).end_of_day rescue ""
    end
    params[:q][:meta_sort] ||= "completed_at.desc"

    @search = Spree::Order.complete.search(params[:q])
    orders = @search.result
    payments = orders.map { |o| o.payments.select { |payment| payment.completed? } }.flatten # Only select completed payments

    @distributors = Enterprise.is_distributor
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

  def order_cycles
    params[:q] = {} unless params[:q]

    if params[:q][:completed_at_gt].blank?
      params[:q][:completed_at_gt] = Time.zone.now.beginning_of_month
    else
      params[:q][:completed_at_gt] = Time.zone.parse(params[:q][:completed_at_gt]) rescue Time.zone.now.beginning_of_month
    end

    if params[:q] && !params[:q][:completed_at_lt].blank?
      params[:q][:completed_at_lt] = Time.zone.parse(params[:q][:completed_at_lt]) rescue ""
    end
    params[:q][:meta_sort] ||= "completed_at.desc"

    @search = Spree::Order.complete.search(params[:q])
    orders = @search.result
    line_items = orders.map { |o| o.line_items }.flatten
    #payments = orders.map { |o| o.payments.select { |payment| payment.completed? } }.flatten # Only select completed payments

    @distributors = Enterprise.is_distributor
    #@suppliers = Enterprise.is_primary_producer
    @order_cycles = OrderCycle.active_or_complete.order('orders_close_at DESC')
    @report_type = params[:report_type]

    case params[:report_type]
    when "order_cycle_supplier_totals"
      table_items = line_items
      @include_blank = 'All'

      header = ["Supplier", "Product", "Variant", "Amount", "Cost per Unit", "Total Cost", "Status", "Incoming Transport"]

      columns = [ proc { |line_items| line_items.first.variant.product.supplier.name },
        proc { |line_items| line_items.first.variant.product.name },
        proc { |line_items| line_items.first.variant.options_text },
        proc { |line_items| line_items.sum { |li| li.quantity } },
        proc { |line_items| line_items.first.variant.price },
        proc { |line_items| line_items.sum { |li| li.quantity * li.variant.price } },
        proc { |line_items| "" },
        proc { |line_items| "incoming transport" } ]

        rules = [ { group_by: proc { |line_item| line_item.variant.product.supplier },
          sort_by: proc { |supplier| supplier.name } },
          { group_by: proc { |line_item| line_item.variant.product },
          sort_by: proc { |product| product.name } },
          { group_by: proc { |line_item| line_item.variant },
          sort_by: proc { |variant| variant.options_text } } ]

    when "order_cycle_supplier_totals_by_distributor"
      table_items = line_items
      @include_blank = 'All'

      header = ["Supplier", "Product", "Variant", "To Distributor", "Amount", "Cost per Unit", "Total Cost", "Shipping Method"]

      columns = [ proc { |line_items| line_items.first.variant.product.supplier.name },
        proc { |line_items| line_items.first.variant.product.name },
        proc { |line_items| line_items.first.variant.options_text },
        proc { |line_items| line_items.first.order.distributor.name },
        proc { |line_items| line_items.sum { |li| li.quantity } },
        proc { |line_items| line_items.first.variant.price },
        proc { |line_items| line_items.sum { |li| li.quantity * li.variant.price } },
        proc { |line_items| "shipping method" } ]

      rules = [ { group_by: proc { |line_item| line_item.variant.product.supplier },
        sort_by: proc { |supplier| supplier.name } },
        { group_by: proc { |line_item| line_item.variant.product },
        sort_by: proc { |product| product.name } },
        { group_by: proc { |line_item| line_item.variant },
        sort_by: proc { |variant| variant.options_text },
        summary_columns: [ proc { |line_items| "" },
          proc { |line_items| "" },
          proc { |line_items| "" },
          proc { |line_items| "TOTAL" },
          proc { |line_items| line_items.sum { |li| li.quantity } },
          proc { |line_items| line_items.first.variant.price },
          proc { |line_items| line_items.sum { |li| li.quantity * li.variant.price } },
          proc { |line_items| "" } ] },
        { group_by: proc { |line_item| line_item.order.distributor },
        sort_by: proc { |distributor| distributor.name } } ]

    when "order_cycle_distributor_totals_by_supplier"
      table_items = line_items
      @include_blank = 'All'

      header = ["Distributor", "Supplier", "Product", "Variant", "Amount", "Cost per Unit", "Total Cost", "Total Shipping Cost", "Shipping Method"]

      columns = [ proc { |line_items| line_items.first.order.distributor.name },
        proc { |line_items| line_items.first.variant.product.supplier.name },
        proc { |line_items| line_items.first.variant.product.name },
        proc { |line_items| line_items.first.variant.options_text },
        proc { |line_items| line_items.sum { |li| li.quantity } },
        proc { |line_items| line_items.first.variant.price },
        proc { |line_items| line_items.sum { |li| li.quantity * li.variant.price } },
        proc { |line_items| "" },
        proc { |line_items| "shipping method" } ]

      rules = [ { group_by: proc { |line_item| line_item.order.distributor },
        sort_by: proc { |distributor| distributor.name },
        summary_columns: [ proc { |line_items| "" },
          proc { |line_items| "TOTAL" },
          proc { |line_items| "" },
          proc { |line_items| "" },
          proc { |line_items| "" },
          proc { |line_items| "" },
          proc { |line_items| line_items.sum { |li| li.quantity * li.variant.price } },
          proc { |line_items| line_items.map { |li| li.order }.uniq.sum { |o| o.ship_total } },
          proc { |line_items| "" } ] },
        { group_by: proc { |line_item| line_item.variant.product.supplier },
        sort_by: proc { |supplier| supplier.name } },
        { group_by: proc { |line_item| line_item.variant.product },
        sort_by: proc { |product| product.name } },
        { group_by: proc { |line_item| line_item.variant },
        sort_by: proc { |variant| variant.options_text } } ]

    when "order_cycle_customer_totals"
      table_items = line_items
      @include_blank = 'All'

      header = ["Distributor", "Customer", "Email", "Phone", "Product", "Variant", "Amount", "Item ($)", "Ship ($)", "Total ($)", "Paid?", "Packed?", "Shipped?"]

      columns = [ proc { |line_items| line_items.first.order.distributor.name },
        proc { |line_items| line_items.first.order.bill_address.firstname + " " + line_items.first.order.bill_address.lastname },
        proc { |line_items| line_items.first.order.email },
        proc { |line_items| line_items.first.order.bill_address.phone },
        proc { |line_items| line_items.first.variant.product.name },
        proc { |line_items| line_items.first.variant.options_text },
        proc { |line_items| line_items.sum { |li| li.quantity } },
        proc { |line_items| line_items.sum { |li| li.quantity * li.variant.price } },
        proc { |line_items| "" },
        proc { |line_items| "" },
        proc { |line_items| "" },
        proc { |line_items| "" },
        proc { |line_items| "" } ]

    rules = [ { group_by: proc { |line_item| line_item.order.distributor },
      sort_by: proc { |distributor| distributor.name } },
      { group_by: proc { |line_item| line_item.order },
      sort_by: proc { |order| order.bill_address.lastname + " " + order.bill_address.firstname },
      summary_columns: [ proc { |line_items| "" },
        proc { |line_items| "" },
        proc { |line_items| "" },
        proc { |line_items| "" },
        proc { |line_items| "TOTAL" },
        proc { |line_items| "" },
        proc { |line_items| "" },
        proc { |line_items| line_items.sum { |li| li.quantity * li.variant.price } },
        proc { |line_items| line_items.map { |li| li.order }.uniq.sum { |o| o.ship_total } },
        proc { |line_items| line_items.map { |li| li.order }.uniq.sum { |o| o.total } },
        proc { |line_items| line_items.map { |li| li.order.paid? }.all? { |paid| paid == true } ? "Yes" : "No" },
        proc { |line_items| "" },
        proc { |line_items| "" } ] },
      { group_by: proc { |line_item| line_item.variant.product },
      sort_by: proc { |product| product.name } },
      { group_by: proc { |line_item| line_item.variant },
       sort_by: proc { |variant| variant.options_text } } ]

    else
      table_items = line_items
      @include_blank = 'All'

      header = ["Supplier", "Product", "Variant", "Amount", "Cost per Unit", "Total Cost", "Status", "Incoming Transport"]

      columns = [ proc { |line_items| line_items.first.variant.product.supplier.name },
        proc { |line_items| line_items.first.variant.product.name },
        proc { |line_items| line_items.first.variant.options_text },
        proc { |line_items| line_items.sum { |li| li.quantity } },
        proc { |line_items| line_items.first.variant.price },
        proc { |line_items| line_items.sum { |li| li.quantity * li.variant.price } },
        proc { |line_items| "" },
        proc { |line_items| "incoming transport" } ]

      rules = [ { group_by: proc { |line_item| line_item.variant.product.supplier },
        sort_by: proc { |supplier| supplier.name } },
        { group_by: proc { |line_item| line_item.variant.product },
        sort_by: proc { |product| product.name } },
        { group_by: proc { |line_item| line_item.variant },
        sort_by: proc { |variant| variant.options_text } } ]

    end

    order_grouper = OpenFoodWeb::OrderGrouper.new rules, columns

    @header = header
    @table = order_grouper.table(table_items)
    csv_file_name = "order_cycles.csv"

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
